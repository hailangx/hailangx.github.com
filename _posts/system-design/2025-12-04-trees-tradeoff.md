---
layout: post
title: "Index Trees - One Pager"
date: 2025-12-04
categories: [system-design]
tags: [db, index, architecture]
---

## Overview

Index structures are fundamental to database performance, determining how efficiently systems can handle reads, writes, and range queries. The choice of index tree depends on your workload characteristics, concurrency requirements, and whether data lives primarily in memory or on disk.

**For in-memory workloads**, structures like **skiplists** and **AVL/RB trees** provide fast lookups with simple implementations. Skiplists are particularly attractive for concurrent scenarios due to their lock-free friendliness, making them ideal for Redis's sorted sets and LSM-tree memtables.

**For disk-based OLTP systems**, the **B+ tree** remains dominant (MySQL, PostgreSQL) thanks to its shallow structure that minimizes disk I/O and excellent cache locality. However, it struggles with write-heavy workloads due to random I/O patterns and the need for latches under concurrency.

**For high-concurrency systems**, the **Bw-tree** offers lock-free operation through delta records and mapping tables, making it ideal for modern in-memory databases like Azure Cosmos DB and SQL Server's Hekaton engine, especially on SSDs.

**For write-intensive workloads**, **LSM-trees** excel by converting random writes into sequential I/O through an append-only design with background compaction. This makes them the go-to choice for distributed databases (Cassandra, DynamoDB) and storage engines (RocksDB), though they trade off read performance and latency predictability.

**For multidimensional queries**, **BKD-trees** (used in Lucene/Elasticsearch) efficiently handle range and geospatial searches through space partitioning, though they're optimized for bulk indexing rather than transactional updates.

The key insight: **there is no universal best index structure**. B+ trees optimize for read-heavy OLTP, LSM-trees for write-heavy distributed systems, Bw-trees for lock-free concurrency, and BKD-trees for spatial queries. Understanding these trade-offs is essential for system design interviews and production architecture decisions.

---

## Comparison Table

| **Structure**     | **Best For**                                | **Used In**                           | **Strengths**                                                          | **Weaknesses**                                                             |
| ----------------- | ------------------------------------------- | ------------------------------------- | ---------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| **Skiplist**      | In-memory sorted sets, range scans          | Redis, LevelDB/RocksDB (memtable)     | Simple, lock-free friendly, fast range scans                           | No strict worst-case bounds, more memory overhead                          |
| **AVL / RB Tree** | In-memory ordered maps                      | C++ `std::map`, Java `TreeMap`, Linux | Deterministic *O(log n)* ops, fast lookups (AVL), fewer rotations (RB) | Poor cache locality, slower under concurrency, outperformed by B+ in scale |
| **B+ Tree**       | Disk-based point & range queries            | MySQL, PostgreSQL, Oracle, NTFS       | Very fast range scans, shallow tree (few I/Os), cache-efficient        | Random writes costly, fragmentation, needs latching                        |
| **Bw-Tree**       | High-concurrency, in-memory + disk indexing | Azure Cosmos DB, SQL Server (Hekaton) | Lock-free, SSD-friendly, fast reads/writes with delta records          | Complex to implement, delta chain overhead, needs GC/consolidation         |                         |
| **LSM-Tree**      | Write-heavy storage engines                 | Cassandra, RocksDB, HBase, ScyllaDB, DynamoDB  | High write throughput, sequential I/O, good compression, Bloom filters | Read/compaction amplification, less predictable latency                    |
| **BKD-Tree**      | Multidimensional numeric & geo queries      | Lucene, Elasticsearch, CrateDB        | Excellent for range & geo queries, compact, SIMD-friendly leaf blocks  | Not for OLTP, bulk-write oriented, less dynamic   