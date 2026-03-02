---
layout: post
title: "CodingAgent Architecture & Design"
description: "A deep dive into the internal architecture of CodingAgent — a terminal-based agentic coding assistant, covering the core loop, tool system, parallel execution, caching, sub-agents, context management, and more."
categories: [AI, Software Engineering]
tags: [coding agents, architecture, LLM, tool use, caching, multi-agent]
---

> Design document for the CodingAgent codebase.
> Last updated: 2026-02-25.

---

## 1. Overview

CodingAgent is a terminal-based agentic coding assistant. It runs a recursive
loop: call the Claude API → parse tool-use blocks → execute tools → feed results
back → repeat until the model stops emitting tool calls.

**Key properties:**
- Single-file ESM TypeScript project (no build step required via `tsx`)
- 9 built-in tools (Read, Write, Edit, Glob, Grep, Bash, Task, WebFetch, WebSearch)
- Parallel execution of read-only tools, barrier semantics for write tools
- Multi-level sub-agent spawning with context isolation
- Two-tier context compaction (micro + auto)
- Smart exploration cache with file-level invalidation
- Session persistence and resume
- Multi-judge eval gate for verifying task completion (opt-in via `--eval`)

---

## 2. Project Structure

```
codingagent/
├── package.json                        # ESM TypeScript, Anthropic SDK + glob + diff deps
├── tsconfig.json                       # ES2022, NodeNext module, strict mode
├── src/
│   ├── index.ts                        # Entry point: CLI arg parsing, REPL, command handlers
│   ├── ansi-diff.d.ts                  # Type declarations for ansi-diff module
│   │
│   ├── core/                           # Core agent engine
│   │   ├── types.ts                    # Core type definitions (Message, Tool, ToolContext, etc.)
│   │   ├── client.ts                   # Anthropic SDK client singleton
│   │   ├── context.ts                  # ToolContext creation + sub-agent context cloning
│   │   ├── loop.ts                     # Core agentic loop (streaming API + tool execution)
│   │   ├── agent.ts                    # Sub-agent spawning (Explore, Plan, Bash, general-purpose)
│   │   ├── compaction.ts               # Token estimation, context compaction, micro-compaction
│   │   ├── streaming-executor.ts       # Parallel tool execution engine with concurrency control
│   │   └── mcp-client.ts              # MCP (Model Context Protocol) server connections
│   │
│   ├── config/                         # Configuration & skill loading
│   │   ├── config.ts                   # Config loading from env + ~/.claude/settings.json
│   │   └── skills.ts                   # Skill/instruction file loading (Claude, Copilot, etc.)
│   │
│   ├── tools/                          # Built-in tool implementations
│   │   ├── index.ts                    # Tool registry (10 tools)
│   │   ├── read.ts                     # File read with line numbers, offset/limit, image support
│   │   ├── write.ts                    # Atomic file writes with directory creation
│   │   ├── edit.ts                     # Exact string replacement with diff preview
│   │   ├── glob.ts                     # File pattern matching (sorted by mtime)
│   │   ├── grep.ts                     # ripgrep-based search (regex, file types, context)
│   │   ├── bash.ts                     # Shell command execution with timeout + env sanitization
│   │   ├── task.ts                     # Sub-agent spawning tool
│   │   ├── web.ts                      # WebFetch + WebSearch
│   │   ├── open.ts                     # Open files/URLs in native apps
│   │   ├── validate.ts                 # Input validation helpers
│   │   └── fs-utils.ts                 # Atomic file replacement utility
│   │
│   ├── ports/                          # Transport I/O abstractions
│   │   ├── io-port.ts                  # IOPort interface (InputPort + OutputPort)
│   │   ├── io-port.test.ts             # IOPort tests
│   │   ├── terminal-port.ts            # Terminal stdin/stdout IOPort adapter
│   │   ├── telegram-port.ts            # Telegram Bot API IOPort adapter
│   │   └── teams-port.ts              # Microsoft Teams IOPort adapter
│   │
│   ├── session/                        # Session persistence & runner
│   │   ├── session.ts                  # Save/load sessions to ~/.codingagent/sessions/
│   │   └── session-runner.ts           # Transport-agnostic session loop driver
│   │
│   ├── eval/                           # Work quality evaluation
│   │   └── eval.ts                     # Multi-judge eval gate (correctness, completeness, goal)
│   │
│   ├── ui/                             # Terminal UI & REPL
│   │   ├── ui.ts                       # Colors, spinners, formatting, OutputManager
│   │   ├── commands.ts                 # REPL slash-command registry & metadata
│   │   └── frecency.ts                 # Command usage frequency × recency tracker
│   │
│   ├── utils/                          # Shared utilities
│   │   ├── retry.ts                    # Retry/backoff, abort-aware sleep, signal combiners
│   │   └── explore-cache.ts            # LRU exploration cache with mtime/TTL invalidation
│   │
│   ├── gateway/                        # Multi-transport gateway
│   │   ├── gateway.ts                  # Gateway host process (manages transports + worker)
│   │   ├── ipc-protocol.ts             # IPC message types (host ↔ worker)
│   │   └── agent-worker.ts             # Forked child process running the agent
│   │
│   └── scripts/                        # Standalone entry points
│       ├── telegram.ts                 # Telegram bot entry point
│       └── teams.ts                    # Teams bot entry point
│
└── dist/                               # Compiled output (mirrors src/ structure)
```

---

## 3. Core Loop

The agentic loop lives in `loop.ts` and is an async generator (`agenticLoop()`):

```
User prompt
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  while (true) {                                         │
│    1. Micro-compaction  — trim old tool results (>10KB)  │
│    2. Auto-compaction   — summarize if near token limit  │
│    3. API call          — stream response from Claude    │
│    4. Parse tool_use    — queue to StreamingToolExecutor │
│       (tools start executing DURING streaming)          │
│    5. Collect results   — async generator yields them    │
│    6. If stop_reason == "tool_use" → loop               │
│    7. If stop_reason == "end_turn":                     │
│       a. If eval disabled → break                       │
│       b. Run multi-judge eval gate (§15):               │
│          ├─ Judges evaluate in parallel                  │
│          ├─ Majority pass → break                       │
│          └─ Majority fail → inject refinement → loop    │
│  }                                                      │
└─────────────────────────────────────────────────────────┘
    │
    ▼
Assistant response displayed to user
```

**Retry logic:** 3 retries with exponential backoff (1s base, 30s cap, ±25% jitter).
Non-retryable: 400, 401, 403, 404. Retryable: 429, 529, 5xx.

---

## 4. Tool System

### 4.1. Tool Interface

```typescript
interface Tool {
  name: string;
  description: string;
  inputSchema: Anthropic.Tool["input_schema"];
  isConcurrencySafe: boolean;          // true → can run in parallel
  execute(input, context): Promise<ToolResult>;
}
```

### 4.2. Tool Categories

| Category | Tools | Concurrency-Safe | Cacheable |
|----------|-------|:-:|:-:|
| **File Read** | Read | ✅ | ✅ |
| **File Search** | Glob, Grep | ✅ | ✅ |
| **File Write** | Write, Edit | ❌ | ❌ (invalidates cache) |
| **Execution** | Bash | ❌ | ❌ (invalidates cache) |
| **Agent** | Task | ✅ (background) | ❌ |
| **Web** | WebFetch, WebSearch | ✅ | ❌ |

### 4.3. Read-Before-Write Guard

Both `Write` and `Edit` enforce a read-before-write invariant via `readFileState` (LRU, 500 entries):

1. **Has the file been read?** — `readFileState.get(path)` must exist
2. **Is it stale?** — Compare current mtime against saved timestamp (1s tolerance)
3. If either fails → error, model must re-read

This prevents blind overwrites and catches external modifications.

### 4.4. Atomic File Operations

Both `Write` and `Edit` use atomic writes:
- Write to a temp file (`openSync("wx")`, exclusive create)
- `renameSync(tmp, target)` — atomic on same filesystem
- Fallback: copy + unlink for cross-filesystem (EXDEV)
- Symlink-aware: resolves to real path before replacing

---

## 5. Parallel Tool Execution

`StreamingToolExecutor` (in `streaming-executor.ts`) manages concurrency:

```
┌──────────────────────────────────────────────────────────┐
│  CONCURRENCY RULES                                        │
│                                                          │
│  Safe tools (Read, Glob, Grep, WebFetch, WebSearch):     │
│    → Run in parallel (max 8 concurrent)                  │
│    → Blocked if any unsafe tool is running               │
│                                                          │
│  Unsafe tools (Write, Edit, Bash):                       │
│    → Run alone (barrier semantics)                       │
│    → Block until all prior tools finish                  │
│    → Nothing starts until barrier completes              │
│                                                          │
│  Example: [Read₁, Read₂, Write₃, Read₄]                 │
│                                                          │
│    Read₁  ████████                                       │
│    Read₂  ████████        (parallel)                     │
│                    Write₃ ██████████  (barrier, alone)   │
│                                      Read₄ ████  (after) │
└──────────────────────────────────────────────────────────┘
```

**Key optimization:** Tools start executing DURING API streaming. As each `tool_use`
block is fully parsed, it's immediately queued — file reads can complete before the
model finishes generating subsequent tool calls.

---

## 6. Exploration Cache

### 6.1. Purpose

When the agent explores a codebase, it often re-reads the same files and re-runs
the same searches across turns. The Exploration Cache stores results from read-only
tools (`Read`, `Glob`, `Grep`) and returns cached results when the same tool call
is repeated — avoiding redundant disk I/O and subprocess spawning.

### 6.2. Architecture

```
┌─────────────────────────────────────────────────────────┐
│  StreamingToolExecutor.executeTool()                     │
│                                                         │
│  ┌─── Read/Glob/Grep ────────┐  ┌── Write/Edit/Bash ──┐│
│  │                            │  │                     ││
│  │  1. cache.get(tool, input) │  │  After execution:   ││
│  │     ├─ HIT  → return cached│  │  → invalidateFile() ││
│  │     └─ MISS → execute tool │  │  → invalidateDir()  ││
│  │  2. Validate freshness:    │  │    (for Bash)       ││
│  │     ├─ Read: check mtime   │  │                     ││
│  │     └─ Glob/Grep: check TTL│  │                     ││
│  │  3. cache.set(tool, result)│  │                     ││
│  └────────────────────────────┘  └─────────────────────┘│
│                    ↕                       ↕             │
│            ┌──────────────┐                              │
│            │ ExploreCache  │                              │
│            │  LRU Map      │                              │
│            │  max: 200     │                              │
│            │  TTL: 30s     │                              │
│            │  (Glob/Grep)  │                              │
│            └──────────────┘                              │
└─────────────────────────────────────────────────────────┘
```

### 6.3. Cache Key

Deterministic SHA-256 hash of:
```
SHA-256({ tool: "Read", input: { file_path: "/src/foo.ts", ... }, cwd: "/project" })
```
Input properties are sorted by key name before hashing to ensure identical tool
calls with different property ordering produce the same key.

### 6.4. Freshness Validation

| Tool | Validation Strategy | Rationale |
|------|---------------------|-----------|
| **Read** | `statSync(path).mtimeMs` compared to cached mtime | Single syscall (~0.1ms) vs full file read (~1-10ms). Catches external edits. |
| **Glob** | TTL (default 30s) | Can't efficiently mtime-check all files matching a pattern. |
| **Grep** | TTL (default 30s) | Same — searches span many files. |

### 6.5. Invalidation Strategy

The cache is invalidated at multiple levels to ensure correctness:

```
┌─────────────────────────────────────────────────────────────┐
│  INVALIDATION TRIGGERS                                       │
│                                                             │
│  1. File-level (Write, Edit):                               │
│     → Remove all Read entries for the modified path         │
│     → Remove Glob/Grep entries whose searchScope            │
│       includes the modified path                            │
│                                                             │
│  2. Directory-level (Bash):                                 │
│     → We can't know which files Bash touched                │
│     → Conservatively invalidate ALL entries under cwd       │
│     → Both Read entries under the dir AND                   │
│       Glob/Grep entries whose scope overlaps the dir        │
│                                                             │
│  3. Manual (REPL commands, session lifecycle):              │
│     → /clear     → cache.clear()                            │
│     → /undo      → cache.clear() (git stash changes files)  │
│     → /resume    → cache.clear() (files may have changed)   │
│     → Session reset → cache.clear()                         │
│                                                             │
│  4. Automatic (per-entry):                                  │
│     → Read: mtime mismatch on cache hit → evict + re-exec  │
│     → Glob/Grep: TTL expired → evict + re-exec             │
│     → LRU eviction when cache exceeds 200 entries           │
│                                                             │
│  5. Error results are NEVER cached                          │
│     → Transient errors (ENOENT, EACCES) should be retried  │
│     → Caching an error would mask the fix                   │
└─────────────────────────────────────────────────────────────┘
```

### 6.6. Sub-Agent Integration

When a sub-agent is spawned (`cloneContext`):
- The parent's explore cache is **shallow-cloned** to the child
- The child inherits all cached exploration results
- The child's invalidations do NOT propagate back to the parent
- This matches the isolation model used by `readFileState`

### 6.7. Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `maxEntries` | 200 | LRU eviction cap |
| `directoryTtlMs` | 30,000 | TTL for Glob/Grep entries |
| `enabled` | true | Kill switch |

### 6.8. Monitoring

Use the `/cache` REPL command:

```
/cache
Explore Cache
  Entries:      12
  Hits:         47
  Misses:       15
  Invalidations: 3
  Evictions:    0
  Hit rate:     75.8%
```

---

## 7. Sub-Agent System

### 7.1. Agent Types

| Type | Model | Tools | Purpose |
|------|-------|-------|---------|
| **Explore** | Small (Haiku) | Read, Glob, Grep | Fast read-only codebase exploration |
| **Plan** | Main | Read, Glob, Grep | Architecture & implementation planning |
| **Bash** | Main | Bash | Focused command execution |
| **general-purpose** | Main | All | Multi-step research, broad analysis |

### 7.2. Context Isolation

Each sub-agent receives a cloned context:

```typescript
cloneContext(parent) → {
  readFileState: parent.readFileState.clone(),   // Independent copy
  exploreCache:  parent.exploreCache.clone(),    // Inherits cached data
  abortController: childAbort,                   // Linked to parent
  agentId: randomUUID(),                         // Unique identity
  depth: parent.depth + 1,                       // Nesting depth
}
```

- **AbortController linkage:** Aborting the parent aborts all children. Not vice versa.
- **Max depth:** 5 levels of nesting (`MAX_AGENT_DEPTH`).
- Sub-agents can run in **foreground** (blocking) or **background** (fire-and-forget).

---

## 8. Context Management

### 8.1. Token Estimation

Simple heuristic: ~4 chars/token + per-message overhead. Includes system prompt.

### 8.2. Micro-Compaction (per-turn)

After each turn, tool results older than the 3 most recent and larger than 10KB
are replaced with truncation notices: `"[content truncated — X chars]"`.

### 8.3. Auto-Compaction (threshold-based)

When estimated tokens exceed the compaction threshold (default 160K):
1. The small model (Haiku) summarizes the conversation
2. Old messages are replaced with the summary
3. The 6 most recent messages are preserved
4. `readFileState` and `exploreCache` are cleared

### 8.4. Orphaned Tool-Use Repair

If a `tool_use` block has no matching `tool_result` (from aborts, compaction, or
force-quit during a turn), synthetic `tool_result` entries are injected so the API
doesn't reject the conversation with a 400 error.

---

## 9. Session Persistence

Sessions are saved to `~/.codingagent/sessions/<id>.json`:

```typescript
{
  id: string;
  metadata: { model, cwd, startedAt, lastActiveAt, summary };
  messages: Message[];
}
```

- **Auto-save:** After every turn + on process exit (SIGINT, SIGTERM, beforeExit)
- **Fast metadata:** `extractMetadataFast()` reads only the first 4KB for listing
- **Resume:** `/resume [id]` or `--resume [id]` restores messages + clears stale caches

---

## 10. Configuration

Sources (in precedence order):
1. `~/.claude/settings.json` → `env` object
2. `process.env`
3. Hardcoded defaults

| Config | Env Var | Default |
|--------|---------|---------|
| Model | `ANTHROPIC_MODEL` | `claude-sonnet-4-20250514` |
| Small model | `ANTHROPIC_SMALL_FAST_MODEL` | `claude-haiku-3-5-20241022` |
| Base URL | `ANTHROPIC_BASE_URL` | `https://api.anthropic.com` |
| API key | `ANTHROPIC_API_KEY` | (required) |
| Max output tokens | `ANTHROPIC_MAX_OUTPUT_TOKENS` | `16384` |
| Compaction threshold | `ANTHROPIC_COMPACTION_THRESHOLD` | `160000` |
| Debug mode | `CODINGAGENT_DEBUG` | `false` |
| Skill directories | `skillDirs` (settings.json only) | `[]` (built-in defaults always loaded) |

---

## 11. Terminal Output

### 11.1. The Problem

Node's `readline` module manages the REPL prompt on stdout. Internally, it tracks
how many display rows the prompt occupies (`prevRows`). Every prompt redraw
(`_refreshLine`) moves the cursor UP by `prevRows`, then calls `clearScreenDown`
to erase everything below. This means any text written to stdout asynchronously
(e.g., from MCP server loading, background agent completion, config hot-reload
notifications) gets wiped by readline's next redraw — appearing to flash and
then disappear.

### 11.2. Architecture

All terminal output routes through a centralized `OutputManager` singleton:

```
┌──────────────────────────────────────────────────────────┐
│  Modules (loop.ts, config.ts, mcp-client.ts, session.ts, │
│           tools/index.ts, streaming-executor.ts, etc.)   │
│                                                          │
│  printWarning("…")  printInfo("…")  printSuccess("…")   │
│        │                  │                │              │
│        └──────────────────┼────────────────┘              │
│                           ▼                              │
│                    ┌─────────────┐                        │
│                    │OutputManager│ (singleton in ui.ts)   │
│                    │ .log()      │                        │
│                    │ .info()     │                        │
│                    │ .warn()     │                        │
│                    │ .success()  │                        │
│                    │ .write()    │                        │
│                    └──────┬──────┘                        │
│                           │                              │
│              ┌────────────┼────────────┐                 │
│              ▼                         ▼                 │
│     ┌─────────────────┐      ┌─────────────────┐        │
│     │ Non-interactive  │      │ Interactive      │        │
│     │ (-p, piped stdin)│      │ (REPL mode)      │        │
│     │                  │      │                  │        │
│     │ console.log(text)│      │ 1. clearHints()  │        │
│     │ (direct)         │      │ 2. \r\x1b[K      │        │
│     │                  │      │ 3. console.log() │        │
│     │                  │      │ 4. prevRows = 0  │        │
│     │                  │      │ 5. rl.prompt()   │        │
│     └─────────────────┘      └─────────────────┘        │
└──────────────────────────────────────────────────────────┘
```

### 11.3. Lifecycle

| Event | Call | Effect |
|-------|------|--------|
| REPL starts (after `rl` + `hintManager` created) | `output.setReadline(rl, hintManager)` | Enables readline-safe path |
| `/reload` (before `rl.close()`) | `output.detachReadline()` | Falls back to direct `console.log` |
| Non-interactive mode (`-p`, piped stdin) | (never called) | Uses `console.log` directly |

### 11.4. Output Channels

| Channel | Target | Used by |
|---------|--------|---------|
| `output.log()` / `.info()` / `.warn()` / `.success()` | stdout (readline-safe) | All modules (via `printInfo`/`printWarning`/`printSuccess`) |
| `output.write()` | stdout (raw, no re-prompt) | Streaming assistant text chunks |
| `Spinner` | stderr | Thinking indicator, compaction progress |
| `console.error` | stderr | Fatal errors, startup failures |

### 11.5. Why Spinner Uses stderr

The `Spinner` class writes exclusively to `process.stderr`. This avoids
interfering with readline's stdout management and ensures spinner output
doesn't contaminate piped stdout in non-interactive mode (`-p`).

---

## 12. Caching & Invalidation Summary

The system has multiple caching layers, each with its own invalidation strategy:

| Cache | Location | Strategy | Invalidation |
|-------|----------|----------|--------------|
| **Config** | `config.ts` | Singleton, lazy init | `cachedConfig = null` on reset |
| **API client** | `client.ts` | Singleton | `onConfigReset` callback |
| **ReadFileState** | `context.ts` | LRU Map (500 entries) | Per-file on write; bulk `clear()` on /undo, /clear, /resume |
| **ExploreCache** | `explore-cache.ts` | LRU Map (200 entries) | File-level (Write/Edit), directory-level (Bash), mtime (Read), TTL (Glob/Grep), manual (REPL commands) |
| **System prompt** | `index.ts` | Session-stable timestamp | New session resets `sessionStartDate` |
| **Tool registry** | `tools/index.ts` | Static Map | Never invalidated (tools are compile-time constants) |
| **Session metadata** | `session.ts` | First-4KB fast path | Re-read on `listSessions()` |

### Data flow between caches

```
                    ┌──────────────────────────────────┐
                    │  User prompt / tool execution     │
                    └──────────────┬───────────────────┘
                                   │
               ┌───────────────────┼───────────────────┐
               │                   │                   │
               ▼                   ▼                   ▼
     ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
     │  ExploreCache    │ │ ReadFileState    │ │  Session Store  │
     │  (tool results)  │ │ (file mtimes)    │ │ (messages)      │
     │                  │ │                  │ │                  │
     │  Read hit? ──────┤ │ Read-before-     │ │ Auto-save after │
     │    → return       │ │ write guard      │ │ each turn       │
     │  Read miss? ─────┤ │                  │ │                  │
     │    → execute      │ │ Edit/Write       │ │ /resume restores│
     │    → store result │ │ updates mtime    │ │ + clears caches │
     │                  │ │                  │ │                  │
     │  Write/Edit?     │ │                  │ │                  │
     │    → invalidate  ◄─┤                  │ │                  │
     │  Bash?           │ │                  │ │                  │
     │    → invalidate  │ │                  │ │                  │
     │      directory   │ │                  │ │                  │
     └─────────────────┘ └─────────────────┘ └─────────────────┘
```

---

## 13. REPL Commands

| Command | Description |
|---------|-------------|
| `/help` | Show all commands |
| `/clear` | Start new conversation (clears caches) |
| `/compact [--force]` | Compress conversation context |
| `/status` | Show token usage, cost, turn count |
| `/cache` | Show explore cache statistics |
| `/model <name>` | Switch model mid-session |
| `/smallmodel <name>` | Switch small model |
| `/tokens` | Show current token count |
| `/history` | Show conversation history |
| `/retry` | Re-send last prompt |
| `/agents [id]` | Show background agent status |
| `/save` | Save current session |
| `/sessions` | List saved sessions |
| `/resume [id]` | Resume a saved session |
| `/delete-session <id>` | Delete a saved session |
| `/undo` | Stash uncommitted changes via git |
| `/reload` | Reload config from settings.json |
| `/quit` | Exit (also Ctrl+C ×2) |

---

## 14. Multi-Judge Eval Gate

### 14.1. Purpose

The eval gate is a verification step that runs after the agent declares its work
complete (stop_reason: `end_turn`). Instead of trusting the agent's judgment that
the task is done, multiple AI "judges" independently evaluate the work from
different perspectives. The loop only terminates when a **majority** of judges
agree the work is complete. Otherwise, the judges' feedback is injected as a
refinement prompt and the agent continues working.

This addresses a core failure mode of agentic loops: the agent produces a
superficially complete response that misses requirements, contains bugs, or
doesn't actually solve the user's problem. Without eval, the user must manually
verify and re-prompt. With eval, the loop self-corrects.

### 14.2. Architecture

```
Agent declares "done" (end_turn, no tool calls)
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  EVAL GATE (up to MAX_EVAL_ROUNDS = 3)                      │
│                                                             │
│  1. Build eval context:                                     │
│     - Original user request (first user message)            │
│     - Agent work summary (last 20 messages: text + tools)   │
│                                                             │
│  2. Run judges IN PARALLEL (Promise.allSettled):             │
│     ┌─────────────┐ ┌──────────────┐ ┌────────────────┐    │
│     │ Correctness  │ │ Completeness │ │ Goal Alignment │    │
│     │              │ │              │ │                │    │
│     │ Bugs?        │ │ All parts    │ │ Does it solve  │    │
│     │ Logic errors?│ │ addressed?   │ │ the real need? │    │
│     │ Syntax valid?│ │ TODOs left?  │ │ User would be  │    │
│     │              │ │              │ │ satisfied?     │    │
│     └──────┬───────┘ └──────┬───────┘ └──────┬─────────┘    │
│            │                │                │              │
│            ▼                ▼                ▼              │
│     { isComplete, reasoning, refinementSuggestions }        │
│                                                             │
│  3. MAJORITY RULE: completeCount > judges.length / 2        │
│     ├─ YES → yield eval_complete(passed: true) → EXIT LOOP  │
│     └─ NO  → synthesize refinement prompt                   │
│              → inject as user message                       │
│              → yield eval_complete(passed: false)            │
│              → CONTINUE LOOP                                │
└─────────────────────────────────────────────────────────────┘
```

### 14.3. Judge Perspectives

Three built-in judges provide complementary viewpoints:

| Judge | Focus | Pass Criteria |
|-------|-------|---------------|
| **Correctness** | Bugs, logic errors, syntax validity, edge cases | Work correctly fulfills the request without errors |
| **Completeness** | All aspects addressed, no TODOs, consistent changes | Every part of the request is covered |
| **Goal Alignment** | User's underlying intent, appropriate approach | The result serves the user's actual need |

Each judge returns a structured JSON verdict:
```json
{
  "isComplete": true,
  "reasoning": "The implementation correctly handles all edge cases...",
  "refinementSuggestions": []
}
```

### 14.4. Majority Rule

The work is accepted when **more than half** of the judges agree it's complete.
With 3 judges, this means 2 must pass. This design:

- **Prevents single-judge blocking:** One overly-strict judge can't hold up
  completion if the other two are satisfied
- **Catches real issues:** When 2+ judges flag problems, there's likely a
  genuine deficiency
- **Avoids ties:** Odd number of judges gives a clear majority

### 14.5. Refinement Loop

When eval fails:

1. Failing judges' reasoning and suggestions are synthesized into a refinement prompt
2. The prompt is injected as a user message into the conversation
3. The agentic loop continues — the model processes the feedback and produces
   a revised response
4. When the model stops again, eval runs again (up to `MAX_EVAL_ROUNDS = 3`)

Example refinement prompt:
```
The following evaluation judges found issues with the work (round 1/3):

**Correctness**: The function doesn't handle null input — it would throw a
TypeError at runtime.
Suggestions:
  - Add a null guard at the start of processData()

**Completeness**: The unit tests were not updated to cover the new function.
Suggestions:
  - Add test cases for processData() in tests/utils.test.ts

Please address the issues above and continue working to fully complete the
original request.
```

### 14.6. Cost & Performance

| Aspect | Detail |
|--------|--------|
| **Model** | Uses `smallModel` (e.g., Haiku) for all judges — fast & cheap |
| **Parallelism** | All judges run simultaneously (`Promise.allSettled`) |
| **Max cost** | 3 judges × 3 rounds × ~100 output tokens = ~900 tokens per eval cycle |
| **Retry** | 2 retries per judge API call (vs 3 for main loop) |
| **Graceful degradation** | If eval API calls fail, the result is accepted without verification |

### 14.7. When Eval is Skipped

Eval is NOT run in these cases:

| Condition | Reason |
|-----------|--------|
| `--eval` not passed | Eval is opt-in to avoid overhead for simple tasks |
| Sub-agents (depth > 0) | Only root agent needs verification |
| stop_reason ≠ `end_turn` | max_tokens, content_filter = abnormal stop, nothing to eval |
| Empty response | No work to evaluate |
| `evalRound ≥ MAX_EVAL_ROUNDS` | Prevent infinite refinement — accept after 3 tries |
| Eval API error | Graceful degradation — accept unverified result |

### 14.8. LoopYield Events

Three new event types are emitted for UI consumption:

| Event | When | Payload |
|-------|------|---------|
| `eval_start` | Beginning of each eval round | `round`, `judgeCount` |
| `eval_judge_verdict` | After each judge responds | `verdict: { judgeName, isComplete, reasoning }`, `round` |
| `eval_complete` | After all judges are aggregated | `passed`, `round`, `refinementPrompt?` |

### 14.9. Usage

```bash
# Enable eval for a one-shot prompt
codingagent --eval -p "Refactor the auth module to use JWT tokens"

# Enable eval in interactive REPL
codingagent --eval
```

---

## 15. Skills & Project Memory

### 15.1. Overview

The skills & memory system loads instruction files from disk and injects them into
the system prompt and/or user messages. It supports multiple ecosystems (Claude Code,
GitHub Copilot, OpenAI Codex, Google Gemini) and provides a slash-command skill
invocation mechanism.

### 15.2. Project Memory (CLAUDE.md)

Memory files are loaded hierarchically. Lower-priority entries appear earlier in the
system prompt; higher-priority entries appear later (giving them implicit precedence).

```
┌─────────────────────────────────────────────────────────────┐
│  MEMORY LOADING ORDER (priority ascending)                   │
│                                                             │
│  Priority 10 — User-level (global, personal):               │
│    ~/.claude/CLAUDE.md                                      │
│    ~/.codex/AGENTS.md           (OpenAI Codex)              │
│                                                             │
│  Priority 20 — Project-level (team-shared):                 │
│    ./CLAUDE.md  or  .claude/CLAUDE.md                       │
│    .github/copilot-instructions.md                          │
│    ./AGENTS.md                  (OpenAI Codex)              │
│    ./GEMINI.md                  (Google Gemini)             │
│                                                             │
│  Priority 25 — Modular rules (with optional path scoping):  │
│    .claude/rules/*.md                                       │
│    .github/instructions/*.instructions.md                   │
│                                                             │
│  Priority 30 — Local overrides (personal, not committed):   │
│    ./CLAUDE.local.md                                        │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- **Import support:** `@path/to/file` lines in CLAUDE.md are inlined (up to 5 levels deep)
- **Path-scoped rules:** YAML frontmatter `paths:` (Claude) or `applyTo:` (Copilot) restricts rules to specific file patterns
- **Truncation:** Individual entries are capped at 10,000 chars to prevent context window exhaustion
- **Caching:** Results are cached per project directory; reset on `/clear`, `/reload`, `/resume`

### 15.3. Skills (SKILL.md)

Skills are reusable specialist prompts that can be invoked as slash commands.

#### 15.3.1. Skill Directory Loading

Skills are loaded from **built-in default directories** (always) plus any
**additional directories** configured via `skillDirs` in settings.json.

```
┌─────────────────────────────────────────────────────────────┐
│  SKILL LOADING ORDER (later wins on name collision)          │
│                                                             │
│  1. ~/.claude/skills/          — Built-in: user-level       │
│  2. .claude/skills/            — Built-in: project-level    │
│  3. config.skillDirs[0]        — Extra: from settings.json  │
│  4. config.skillDirs[1]        — Extra: from settings.json  │
│     ...                                                     │
│                                                             │
│  Directories 1 & 2 are ALWAYS loaded.                       │
│  Directories 3+ are loaded only if configured.              │
│  Later directories override earlier ones on name collision. │
└─────────────────────────────────────────────────────────────┘
```

Configure extra directories in `~/.claude/settings.json`:

```json
{
  "skillDirs": [
    "/shared/team-skills",
    "C:\\company\\prompts",
    "~/my-custom-skills"
  ]
}
```

Path resolution:
- `~` prefix → expanded to user's home directory
- Absolute paths → used as-is
- Relative paths → resolved against the current working directory

#### 15.3.2. SKILL.md Format

Each skill is a markdown file with optional YAML frontmatter:

```markdown
---
name: react-specialist
description: Senior React developer for modern React 19 patterns
disable-model-invocation: false
user-invocable: true
allowed-tools: [Read, Grep, Edit, Write]
context: inline
---

You are a senior React developer. When writing React code...
```

| Frontmatter Field | Type | Default | Description |
|-------------------|------|---------|-------------|
| `name` | string | Parent directory name | Skill identifier (used as `/name` command) |
| `description` | string | `"Skill: {name}"` | One-line description for `/skills` and system prompt |
| `disable-model-invocation` | boolean | `false` | If `true`, skill is hidden from the system prompt |
| `user-invocable` | boolean | `true` | If `false`, skill can't be triggered via `/name` |
| `allowed-tools` | string[] | all | Restrict which tools the skill can use |
| `context` | `"inline"` \| `"fork"` | `"inline"` | `"fork"` runs in an isolated sub-agent |
| `agent` | string | `"general-purpose"` | Sub-agent type when `context: fork` |

#### 15.3.3. How Skills Reach the LLM

Skills are surfaced to the model through two mechanisms:

```
┌─────────────────────────────────────────────────────────────┐
│  A. SYSTEM PROMPT (every API call)                           │
│                                                             │
│  getSystemPrompt()                                          │
│    └── getSkillDescriptions(cwd)                            │
│          └── Filters: disableModelInvocation === false       │
│          └── Appends to system prompt:                      │
│                                                             │
│              Available skills (can be invoked via slash      │
│              commands):                                     │
│              - /react-specialist: Senior React developer... │
│              - /python-pro: Senior Python developer...      │
│                                                             │
│  B. SLASH-COMMAND INVOCATION (on user trigger)              │
│                                                             │
│  User types: /react-specialist fix the useEffect hook       │
│    └── getSkill(cwd, "react-specialist")                    │
│    └── substituteArguments(instructions, args)              │
│          └── $ARGUMENTS → "fix the useEffect hook"          │
│          └── $0 → "fix", $1 → "the", etc.                  │
│    └── Expanded instructions become the user message        │
│    └── Falls through to the agentic loop                    │
└─────────────────────────────────────────────────────────────┘
```

#### 15.3.4. Tab-Completion & Hints Registration

At startup (and after `/clear`, `/reload`):

```
syncSkillCommands(cwd)
  └── getInvocableSkills(cwd)     — filters userInvocable === true
  └── registerSkillCommands()      — registers for tab-completion,
                                     inline hints, /help, and
                                     fuzzy command suggestions
```

### 15.4. Cache Lifecycle

| Event | Memory Cache | Skills Cache |
|-------|-------------|-------------|
| Startup | Loaded from disk | Loaded from disk |
| `/clear` | `resetMemoryCache()` — re-read on next prompt | Reset — re-read + re-sync commands |
| `/reload` | Reset | Reset + re-sync commands |
| `/resume` | Reset (implicit) | Reset (implicit) |
| CWD change | Re-read (different `cachedProjectDir`) | Re-read (different `cachedProjectDir`) |

---

*This document is maintained alongside the source code. When modifying
core systems (loop, tools, caching, agents, eval, skills), update the relevant section.*
