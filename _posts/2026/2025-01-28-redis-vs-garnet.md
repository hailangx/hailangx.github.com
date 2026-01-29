---
layout: post
title: "Redis vs Garnet: Architectural Comparison"
description: "A deep dive comparing the fundamental architectural differences between Redis and Garnet, focusing on their threading models and design philosophies shaped by different hardware eras."
categories: ["System Design"]
tags: [redis, garnet, architecture, caching, distributed-systems]
---

## Executive Summary

This document compares the fundamental architectural differences between Redis (created 2009) and Garnet (created 2020s), focusing on their threading models and design philosophies shaped by different hardware eras.

---

## Historical Context

### When Redis Was Created (2009)

**Redis was created in 2009** by Salvatore Sanfilippo. The computing landscape then:

- **Multi-core CPUs existed** but were less common in servers
  - Dual-core and quad-core were typical
  - 8+ cores were rare and expensive
- **Single-threaded design was pragmatic**: With 2-4 cores, maximizing single-thread performance made sense
- **Simplicity was prioritized**: Redis focused on simplicity, predictability, and ease of debugging
- **Memory was more expensive**: Redis optimized for memory efficiency over CPU parallelism

**Redis's single-threaded model was brilliant for its time** - it eliminated race conditions, locks, and complexity while still being fast enough for most workloads on 2009-era hardware.

### Why Multi-Core Matters Now (2020s)

**Modern servers in 2025-2026** are dramatically different:

| **Then (2009)** | **Now (2020s)** |
|-----------------|-----------------|
| 2-4 cores typical | 64-128+ cores common |
| Few concurrent connections | Thousands of concurrent clients |
| Single-tenant applications | Massive multi-tenant cloud services |
| Lower network bandwidth | 100+ Gbps networking with Accelerated Networking |
| Expensive memory | Abundant, cheaper memory |

**The problem**: A single Redis thread on a 64-core machine leaves 63 cores idle! This wastes expensive cloud resources and limits throughput.

---

## Architectural Differences

### Redis: Single-Threaded Event Loop (Original Design)

```
┌─────────────────────────────────────┐
│  Single Main Thread (Event Loop)    │
│  ┌─────────────────────────────┐    │
│  │ 1. Accept connections        │    │
│  │ 2. Read from sockets         │    │
│  │ 3. Parse commands            │    │
│  │ 4. Execute commands          │    │
│  │ 5. Write responses           │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
     ↓ All operations sequential
     ✗ Can't use multiple cores effectively
```

**Why this design?**
- **Simplicity**: No locks, no race conditions, no concurrency bugs
- **Predictable performance**: Operations execute in strict order
- **Easy to reason about**: Debugging is straightforward
- **Good enough**: For 2-4 cores, this was sufficient
- **Atomic operations**: Natural atomicity without explicit locking

**Limitations**:
- ❌ **CPU bottleneck**: One core maxed out = Redis maxed out
- ❌ **Wasted resources**: 63 cores sitting idle on modern hardware
- ❌ **Latency**: All clients compete for the same thread
- ❌ **Throughput ceiling**: Limited by single-thread performance

---

### Garnet: Shared-Memory Multi-Threaded Design

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Thread 1 (Conn 1)  │  Thread 2 (Conn 2)  │ ... │ Thread N (Conn N)     │
│  ┌────────────────┐ │  ┌────────────────┐ │     │ ┌────────────────┐   │
│  │ Network Recv   │ │  │ Network Recv   │ │     │ │ Network Recv   │   │
│  │      ↓         │ │  │      ↓         │ │     │ │      ↓         │   │
│  │ TLS Decrypt    │ │  │ TLS Decrypt    │ │     │ │ TLS Decrypt    │   │
│  │      ↓         │ │  │      ↓         │ │     │ │      ↓         │   │
│  │ Parse RESP     │ │  │ Parse RESP     │ │     │ │ Parse RESP     │   │
│  │      ↓         │ │  │      ↓         │ │     │ │      ↓         │   │
│  │ Storage Access │ │  │ Storage Access │ │     │ │ Storage Access │   │
│  │      ↓         │ │  │      ↓         │ │     │ │      ↓         │   │
│  │ Send Response  │ │  │ Send Response  │ │     │ │ Send Response  │   │
│  └────────────────┘ │  └────────────────┘ │     │ └────────────────┘   │
└───────────│─────────────────────│──────────────────────────│────────────┘
            │                     │                          │
            └─────────────────────┴──────────────────────────┘
                                  ↓
                    ┌──────────────────────────────┐
                    │  Tsavorite Storage Engine    │
                    │  (Thread-safe, lock-free)    │
                    │  - Concurrent hash table     │
                    │  - Epoch-based GC            │
                    │  - Lock-free algorithms      │
                    └──────────────────────────────┘
```

**Why this design?**
- **Multi-core utilization**: Every connection gets its own thread → uses all available cores
- **Modern hardware optimization**: Designed for 64-128 core servers common in 2020s
- **.NET advantages**: Built on .NET's excellent threading primitives and async/await
- **Cloud economics**: Better resource utilization = lower costs at scale
- **No thread switching**: Each thread does everything (network, TLS, parsing, storage) - no shuffling

**Key principle: "Shared Memory"**
- Data stays in each thread's CPU cache hierarchy (L1/L2/L3)
- No data movement between threads for individual requests
- CPU cache coherence brings data to the processing logic
- Avoids "shuffle-based" designs that move requests between threads

**How it works**:
1. Each client connection gets a dedicated network IO thread
2. That thread does **everything** for that connection on the IO completion path
3. All threads share access to Tsavorite storage (thread-safe via lock-free algorithms)
4. Result: Full hardware utilization with minimal synchronization overhead

---

## Threading Model Comparison

### Redis Cluster: Shuffle-Based Design

When Redis needs to scale, it uses clustering:

```
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  Redis Node 1    │    │  Redis Node 2    │    │  Redis Node 3    │
│  (Slots 0-5460)  │    │  (Slots 5461-10922)   │  (Slots 10923-16383) │
│                  │    │                  │    │                  │
│  Single Thread   │    │  Single Thread   │    │  Single Thread   │
└──────────────────┘    └──────────────────┘    └──────────────────┘
         ↑                       ↑                       ↑
         └───────────────────────┴───────────────────────┘
                  Client must route to correct node
                  (Data movement between nodes)
```

**Characteristics**:
- Multiple processes, each single-threaded
- Data **sharded** by key hash to specific nodes
- Requests must be **routed/shuffled** to the node owning the key
- Cross-slot operations are complex or impossible

**Redis 6.0+ IO Threading**:
- Network IO can use multiple threads
- But command **execution** still single-threaded
- Helps with network bottleneck but not computation

---

### Garnet: Per-Connection Threading

```
┌────────────────────────────────────────────────────┐
│            Single Garnet Process                    │
│                                                     │
│  All threads access shared Tsavorite storage       │
│  No key-based routing required                     │
│  No data shuffling between threads                 │
│                                                     │
│  Thread 1  Thread 2  Thread 3  ...  Thread 64     │
│    │         │         │              │            │
│    └─────────┴─────────┴──────────────┘            │
│                   ↓                                 │
│         ┌────────────────────┐                     │
│         │ Tsavorite Storage  │                     │
│         │ (Shared, thread-safe)                    │
│         └────────────────────┘                     │
└────────────────────────────────────────────────────┘
```

**Characteristics**:
- All threads in one process
- No key-based routing - any thread can access any data
- Lock-free data structures handle concurrency
- "Cache coherence brings data to logic" instead of moving logic to data

---

## Performance Implications

### Example: 64-Core Server, 1000 Concurrent Clients

**Redis (Single Instance)**:
```
Core 1:  ████████████████ (100% busy - all work here)
Core 2:  ░░░░░░░░░░░░░░░░ (idle)
Core 3:  ░░░░░░░░░░░░░░░░ (idle)
Core 4:  ░░░░░░░░░░░░░░░░ (idle)
...
Core 64: ░░░░░░░░░░░░░░░░ (idle)

CPU Utilization: ~1.5% (1/64 cores)
Bottleneck: Single-thread speed
Wasted Capacity: 98.5% of CPU power unused
```

**Garnet**:
```
Core 1:  ████████ (handling ~16 connections)
Core 2:  ████████ (handling ~16 connections)
Core 3:  ████████ (handling ~16 connections)
Core 4:  ████████ (handling ~16 connections)
...
Core 64: ████████ (handling ~16 connections)

CPU Utilization: ~90%+ (all cores working)
Bottleneck: Network or storage (not CPU)
Wasted Capacity: <10%
```

### Latency Characteristics

| **Scenario** | **Redis** | **Garnet** |
|-------------|-----------|------------|
| Single client | ~100-200μs | ~100-200μs (similar) |
| 100 concurrent clients | ~500μs-1ms | ~200-300μs |
| 1000 concurrent clients | 5-10ms (queuing) | <300μs (p99.9) |
| High throughput | CPU-bound ceiling | Scales with cores |

**Why Garnet is faster at scale**:
- No queuing behind single thread
- Each connection processed independently
- Better CPU cache locality (no thread switching)
- Lower context switch overhead

---

## Key Design Trade-offs

### Redis Philosophy

**Priorities**:
1. ✅ **Simplicity**: Easy to understand, debug, and maintain
2. ✅ **Predictability**: Deterministic operation ordering
3. ✅ **Reliability**: 15+ years of battle-tested production use
4. ✅ **Atomic operations**: Natural atomicity without explicit locks
5. ❌ **Multi-core scaling**: Limited by single-thread design

**Best for**:
- Applications that value simplicity over raw performance
- Workloads with moderate concurrency
- Scenarios where single-thread performance is sufficient
- Teams familiar with Redis ecosystem

### Garnet Philosophy  

**Priorities**:
1. ✅ **Modern hardware utilization**: Leverage all cores on modern servers
2. ✅ **Performance at scale**: Optimize for thousands of concurrent connections
3. ✅ **Low latency**: Sub-300μs at p99.9
4. ✅ **Modern .NET**: Lock-free data structures, async/await, cross-platform
5. ❌ **Complexity**: More sophisticated threading model

**Best for**:
- Large-scale cloud services
- High-concurrency workloads
- Cost optimization on multi-core cloud VMs
- Applications built on .NET ecosystem
- Scenarios requiring maximum throughput

---

## Redis's Evolution (Trying to Address Limitations)

### 1. Redis 6.0 (2020): IO Threading
- Network IO can use multiple threads
- Command execution still single-threaded
- **Helps with**: Network bottleneck
- **Doesn't help with**: CPU-bound workloads

### 2. Redis Cluster: Horizontal Sharding
- Run multiple Redis processes
- Each process still single-threaded
- **Helps with**: Scaling beyond single machine
- **Doesn't help with**: Single-machine multi-core utilization
- **Adds complexity**: Key routing, cross-slot limitations

### 3. Newer Alternatives
- **Valkey**: Redis fork with potential multi-threading
- **Dragonfly**: Ground-up rewrite with multi-threading
- **KeyDB**: Multi-threaded Redis fork
- **Garnet**: Microsoft's .NET-based approach

**The fundamental challenge**: These are retrofits onto a single-threaded design. Garnet was designed multi-threaded from day one, with lock-free data structures (Tsavorite) built for this purpose.

---

## Detailed Comparison Table

| **Aspect** | **Redis (2009 design)** | **Garnet (2020s design)** |
|------------|------------------------|---------------------------|
| **Target era** | 2-4 core servers | 64-128+ core servers |
| **Primary workload** | Moderate concurrency | Massive concurrency (1000s of clients) |
| **Philosophy** | Simplicity and predictability | Performance on modern hardware |
| **Threading model** | Single main thread | One thread per connection |
| **Core utilization** | ~1.5% on 64-core | ~90%+ on 64-core |
| **Network layer** | Event loop (epoll/kqueue) | Async IO completion threads |
| **Storage engine** | Hash table + skip lists | Tsavorite (lock-free) |
| **TLS processing** | On main thread | On IO completion thread |
| **Parsing** | On main thread | On IO completion thread |
| **Latency (high load)** | 5-10ms (queuing) | <300μs p99.9 |
| **Throughput ceiling** | Single-thread CPU speed | Scales with cores |
| **Memory model** | Simple allocations | Pooled buffers, tiered storage |
| **When it shines** | Simple workloads, small servers | Large-scale cloud services |
| **Maturity** | 15+ years, battle-tested | New but built on proven tech |
| **Ecosystem** | Massive (clients, tools, docs) | Growing (Redis-compatible) |
| **Language** | C | C# (.NET) |
| **Platform** | Linux-first | Cross-platform (Linux, Windows) |

---

## Tsavorite: Garnet's Secret Weapon

Garnet's multi-threaded design is only possible because of **Tsavorite**, a lock-free key-value storage engine built by Microsoft Research.

### Key Tsavorite Features

1. **Lock-free concurrent hash table**
   - Multiple threads can read/write simultaneously
   - No traditional locks (uses compare-and-swap, atomic operations)
   - Epoch-based memory reclamation

2. **Tiered storage**
   - Hot data in memory (RAM)
   - Warm data on SSD
   - Cold data in cloud storage (Azure)
   - Transparent to application

3. **Fast checkpointing**
   - Non-blocking checkpoints
   - Fast recovery from checkpoints
   - Append-only log for durability

4. **Designed for modern hardware**
   - NUMA-aware
   - Cache-friendly data structures
   - Optimized for NVMe SSDs

**Without Tsavorite's lock-free design**, Garnet's per-connection threading would create massive lock contention. This is why Garnet was designed as an integrated system from day one.

---

## When to Choose Each

### Choose Redis When:
- ✅ You have moderate concurrency needs (< 1000 concurrent clients)
- ✅ You value simplicity and battle-tested reliability
- ✅ You have extensive Redis expertise on your team
- ✅ You need the vast Redis ecosystem (modules, tools, documentation)
- ✅ Your infrastructure is smaller scale (2-8 cores)
- ✅ Single-thread performance meets your needs

### Choose Garnet When:
- ✅ You have high concurrency needs (1000s of concurrent clients)
- ✅ You run on large multi-core servers (32+ cores)
- ✅ You need the lowest possible latency at scale
- ✅ You're already in the .NET ecosystem
- ✅ Cost optimization is critical (better hardware utilization)
- ✅ You're building new systems and can adopt new technology
- ✅ You're using Azure and want managed Cosmos DB Garnet Cache

---

## Conclusion

**Redis** optimized for the hardware and workloads of 2009 - when 2-4 cores were standard and simplicity was paramount. Its single-threaded design was a brilliant choice that created a reliable, predictable, and widely-adopted system.

**Garnet** optimized for the hardware and workloads of 2025 - when 64-128 cores are standard, thousands of concurrent connections are common, and cloud economics demand efficient resource utilization. Its multi-threaded shared-memory design was built from the ground up to leverage modern hardware.

**Both are valid designs for their contexts.** The "best" choice depends on your specific workload, scale, team expertise, and infrastructure. Redis remains an excellent choice for many workloads, while Garnet represents a modern alternative designed for the challenges of 2020s cloud computing.

---

## Further Reading

- **Garnet Documentation**: https://microsoft.github.io/garnet
- **Garnet Research Papers** (FASTER/Tsavorite): https://microsoft.github.io/garnet/docs/research/papers
- **FASTER KV Store (Tsavorite predecessor)**: https://www.microsoft.com/en-us/research/uploads/prod/2018/03/faster-sigmod18.pdf
- **Redis Design**: https://redis.io/topics/internals
- **Garnet Benchmarks**: https://microsoft.github.io/garnet/docs/benchmarking/overview
- **Azure Cosmos DB Garnet Cache**: https://microsoft.github.io/garnet/docs/azure/overview
