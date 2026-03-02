---
layout: post
title: "How Coding Agents Work: From Raw LLMs to Autonomous Agents"
description: "A comprehensive technical report tracing the six-layer stack from next-token prediction to multi-agent orchestration that powers modern coding agents."
categories: [AI, Software Engineering]
tags: [LLM, coding agents, ReAct, tool use, multi-agent, prompt engineering]
---

# How Coding Agents Work: From Raw LLMs to Autonomous Agents

**A Comprehensive Technical Report**

*February 2026 · Research compiled from academic papers, engineering blogs, and product documentation.*

---

## Executive Summary

Coding agents represent one of the most impactful applications of large language models. They have evolved from simple code-completion engines into autonomous systems that can navigate codebases, write and edit files, execute commands, debug failures, and ship working software — sometimes with minimal human intervention.

This report traces the full evolution from **raw LLMs** doing next-token prediction, through the key enablers — **prompt engineering**, **chain-of-thought reasoning**, **tool use**, and **agentic loops** — up to the **multi-agent orchestration systems** used in production today. Each layer builds on the previous one, forming a six-layer stack:

```
┌─────────┬────────────────────────────┬──────────────────────────────────────────────┐
│ Layer 6 │ MULTI-AGENT ORCHESTRATION  │ Coordinator + specialized workers, parallel  │
├─────────┼────────────────────────────┼──────────────────────────────────────────────┤
│ Layer 5 │ AGENTIC LOOP (ReAct)      │ while(not_done): think → act → observe       │
├─────────┼────────────────────────────┼──────────────────────────────────────────────┤
│ Layer 4 │ TOOL USE / FUNCTION CALL  │ File I/O, terminal, search, browser, APIs    │
├─────────┼────────────────────────────┼──────────────────────────────────────────────┤
│ Layer 3 │ SCAFFOLDING               │ Memory, context management, planning, safety │
├─────────┼────────────────────────────┼──────────────────────────────────────────────┤
│ Layer 2 │ PROMPT ENGINEERING        │ System prompts, few-shot, CoT instructions   │
├─────────┼────────────────────────────┼──────────────────────────────────────────────┤
│ Layer 1 │ RAW LLM                   │ Next-token prediction on code corpora        │
└─────────┴────────────────────────────┴──────────────────────────────────────────────┘
```

---

## Table of Contents

1. [Layer 1: The Raw LLM — Next-Token Prediction on Code](#layer-1-the-raw-llm--next-token-prediction-on-code)
2. [Layer 2: Prompt Engineering for Code](#layer-2-prompt-engineering-for-code)
3. [Layer 3: Chain-of-Thought Reasoning](#layer-3-chain-of-thought-reasoning)
4. [Layer 4: Tool Use and Function Calling](#layer-4-tool-use-and-function-calling)
5. [Layer 5: The Agentic Loop — ReAct and Beyond](#layer-5-the-agentic-loop--react-and-beyond)
6. [Layer 6: Scaffolding, Memory, and Context Management](#layer-6-scaffolding-memory-and-context-management)
7. [Real-World Coding Agent Architectures](#real-world-coding-agent-architectures)
8. [Multi-Agent Orchestration](#multi-agent-orchestration)
9. [The Edit-Test-Debug Feedback Loop](#the-edit-test-debug-feedback-loop)
10. [Key Takeaways and the Road Ahead](#key-takeaways-and-the-road-ahead)
11. [References](#references)

---

## Layer 1: The Raw LLM — Next-Token Prediction on Code

### The Fundamental Mechanism

At their core, all code-generating LLMs work by **next-token prediction**. Given a sequence of tokens, the model predicts a probability distribution over the vocabulary for the next token. This seemingly simple mechanism, when applied at scale with billions of parameters trained on massive code corpora, produces remarkably coherent and functional code.

The generation pipeline works as follows:

```
┌─────────────┐   ┌───────────┐   ┌────────────┐   ┌──────────────────────────────┐
│ Source Code  │──>│ Tokenizer │──>│ Embeddings │──>│ Transformer (N layers of     │
└─────────────┘   └───────────┘   └────────────┘   │ self-attention)              │
                                                    └──────────────┬───────────────┘
                                                                   │
                                                                   ▼
┌──────────┐   ┌────────────────┐   ┌──────────────────────────────────────────────┐
│  repeat  │<──│ append to seq  │<──│ Prediction Head (linear + softmax)           │
└────┬─────┘   └────────────────┘   │ → Next Token (greedy / top-p / temperature)  │
     │                              └──────────────────────────────────────────────┘
     └──────────────────────────────────────────────────────────────────────────>↑
```

1. **Tokenization**: Source code is broken into tokens — keywords, identifiers, operators, whitespace, and special characters. Subword tokenizers (BPE) handle rare identifiers by splitting them into known fragments.
2. **Embedding**: Each token is mapped to a high-dimensional vector (e.g., 4096 dimensions).
3. **Transformer Processing**: Multiple layers of self-attention build contextual representations. Each token "attends" to all previous tokens, capturing syntactic relationships (matching braces, variable scoping) and semantic patterns (algorithmic idioms).
4. **Prediction Head**: A final linear layer + softmax produces a probability distribution over the entire vocabulary (~32K–128K tokens).
5. **Decoding**: The next token is selected via greedy search, temperature-based sampling, or nucleus (top-p) sampling.
6. **Autoregressive Loop**: The selected token is appended to the sequence and the process repeats, generating code one token at a time.

### Why Next-Token Prediction Works for Code

Code is **highly structured** with lower entropy than natural language in many contexts:

- **Strict syntax**: Programming languages have formal grammars. After `def foo(`, the model strongly expects parameter names and type annotations.
- **Repetitive patterns**: Common idioms (iterating over lists, error handling, CRUD operations) appear millions of times in training data.
- **Local dependencies**: Variable names, function calls, and import statements create predictable patterns within a file.
- **NL↔PL bridge**: Docstrings, comments, and descriptive variable names create a natural mapping between intent and implementation.

### Landmark Code LLMs

| Model | Year | Parameters | Training Data | HumanEval Score | Key Innovation |
|-------|------|-----------|--------------|----------------|----------------|
| **Codex** (OpenAI) | 2021 | 12B | 159GB Python from 54M GitHub repos | 28.8% → 37.7% | First NL→code generation; created HumanEval benchmark; powered GitHub Copilot |
| **CodeT5** (Salesforce) | 2021 | 220M | CodeSearchNet (6 languages) | — | Encoder-decoder with identifier-aware denoising |
| **Code Llama** (Meta) | 2023 | 7B–34B | 500B+ code tokens | 53% | Long context (16K), infilling, self-instruct fine-tuning |
| **DeepSeek Coder** | 2024 | 1.3B–33B | 2T tokens (87% code) | 79% (33B) | Fill-in-the-blank + repo-level training |
| **Claude 3.5 Sonnet** | 2024 | Undisclosed | Undisclosed | 92% | State-of-the-art reasoning + tool use integration |

**Sources**: [Chen et al., 2021](https://arxiv.org/abs/2107.03374) · [Rozière et al., 2023](https://ai.meta.com/blog/code-llama-large-language-model-coding/) · [Towards Data Science](https://towardsdatascience.com/cracking-the-code-llms-354505c53295/)

### Limitations of Raw LLMs

A raw LLM generating code token-by-token has fundamental limitations:

- **No execution feedback**: It cannot run its own code, see errors, or iterate.
- **No file access**: It cannot read existing codebases or write files.
- **Hallucination**: It invents plausible-looking but incorrect APIs, variable names, or logic.
- **Context limits**: It can only "see" what fits in its context window (historically 2K–8K tokens, now 128K–200K).
- **One-shot generation**: It produces output in a single pass with no ability to revise.

Each subsequent layer in the stack addresses these limitations.

---

## Layer 2: Prompt Engineering for Code

Prompt engineering is the art of **structuring inputs** to extract better outputs from an LLM without changing the model itself. For code generation, several techniques have proven effective:

### System Prompts

System prompts define the model's persona, constraints, and output requirements. They are the most impactful lever for code quality:

```
You are a senior Python developer. Follow these rules:
- Use Python 3.12+ features (match statements, type unions with |)
- Add type hints to all function signatures
- Write Google-style docstrings
- Handle errors explicitly — never use bare except
- Return only the code, no explanations
```

### Zero-Shot vs. Few-Shot

| Technique | Description | Best For |
|-----------|-------------|----------|
| **Zero-shot** | Just describe the task; no examples | Simple, well-defined tasks |
| **Few-shot** | Provide 2–5 input→output examples | Pattern-following, format adherence, edge cases |

Few-shot prompting significantly improves **format adherence** and helps the model understand expected patterns. The quality and diversity of examples matters more than quantity.

### Structured Output

Techniques to constrain the model's output into predictable formats:

- **JSON mode**: Force the model to output valid JSON (OpenAI's `response_format: { type: "json_object" }`).
- **Schema-based**: Define the exact structure of the expected output using JSON Schema.
- **Delimiters**: Use fenced code blocks (` ```python `) to delineate code from explanation.
- **Prompt templates**: Parameterized prompts with placeholders, separating input variables from task logic from output format.

### Best Practices

1. **Be specific** about language version, framework, and coding conventions.
2. **Provide context** — existing code, file structure, imports, and related functions.
3. **Constrain the output** — specify what format, what to include, what to omit.
4. **Use role prompts** — "You are a senior backend engineer at a fintech company..."
5. **Include negative examples** — show what NOT to do alongside what to do.

**Sources**: [DataCamp](https://www.datacamp.com/tutorial/few-shot-prompting) · [Real Python](https://realpython.com/practical-prompt-engineering/)

---

## Layer 3: Chain-of-Thought Reasoning

### What is Chain-of-Thought?

Chain-of-Thought (CoT) prompting asks the model to generate **intermediate reasoning steps** before producing the final answer. Instead of jumping directly from problem statement to code, the model "thinks aloud" — decomposing the problem, identifying the algorithm, considering edge cases, and then implementing.

```
Task: Write a function to find the longest palindromic substring.

Let me think step by step:
1. A palindrome reads the same forwards and backwards.
2. Brute force: check all substrings — O(n³). Too slow.
3. Better approach: expand around centers — O(n²).
4. Each character and each pair of adjacent characters is a potential center.
5. For each center, expand outward while characters match.
6. Track the longest palindrome found.

def longest_palindrome(s: str) -> str:
    ...
```

### Structured Chain-of-Thought (SCoT) for Code

Li et al. (2023) introduced **Structured CoT (SCoT)**, which exploits the fact that all code can be decomposed into three fundamental structures: **sequence**, **branch**, and **loop**. Instead of free-form reasoning, SCoT asks the model to structure its intermediate steps using these programming constructs.

**Results**: SCoT outperformed standard CoT by **up to 13.79% in Pass@1** across HumanEval, MBPP, and MBCPP benchmarks. Human evaluators also preferred SCoT-generated programs.

### Long Chain-of-Thought (Extended Thinking)

Modern reasoning models (OpenAI o1/o3, DeepSeek-R1, Claude with extended thinking) use **long CoT** — spending thousands of tokens reasoning before generating code. This enables:

- Exploring and discarding multiple approaches
- Catching logical errors before they become code
- Verifying correctness through mental simulation
- Handling multi-step problems that require planning

### When CoT Helps (and When It Doesn't)

| Task Complexity | CoT Benefit |
|----------------|-------------|
| Simple (string formatting, basic CRUD) | Minimal — adds unnecessary overhead |
| Medium (data structures, algorithms) | Moderate improvement |
| Complex (system design, multi-step logic) | Significant improvement |
| Adversarial (tricky edge cases) | Critical for correctness |

**Sources**: [Li et al., 2023](https://arxiv.org/abs/2305.06599) · [OpenReview: Revisiting CoT](https://openreview.net/forum?id=wSZeQoJ1Vk)

---

## Layer 4: Tool Use and Function Calling

### The Breakthrough: From Text to Actions

Tool use (function calling) is the capability that transforms an LLM from a **text generator** into an **agent**. Instead of only producing text, the model can generate structured requests to execute external functions — reading files, running commands, searching the web, calling APIs.

### How Function Calling Works

The technical flow has five steps:

```
┌──────────┐     ┌───────────┐     ┌──────────┐     ┌───────────┐     ┌──────────┐
│  Define  │────>│  Model    │────>│ Execute  │────>│  Return   │────>│  Final   │
│  Tools   │     │  Decides  │     │ Function │     │  Results  │     │ Response │
│ (schema) │     │ (call or  │     │ (app     │     │ (to model)│     │ (text)   │
│          │     │  respond) │     │  code)   │     │           │     │          │
└──────────┘     └───────────┘     └──────────┘     └───────────┘     └──────────┘
```

1. **Define tools**: Provide JSON Schema descriptions of available functions — name, description, parameters with types.
2. **Model decides**: Given the prompt and tool definitions, the model either generates a direct text response OR returns one or more **tool calls** with structured JSON arguments.
3. **Execute**: Application code parses the tool call, invokes the actual function, and captures the result.
4. **Return results**: The function output is sent back to the model as a message with role `"tool"`.
5. **Final response**: The model incorporates the tool result and generates the next response (which may include more tool calls).

### Example: OpenAI Function Calling

```python
# Step 1: Define the tool
tools = [{
    "type": "function",
    "function": {
        "name": "read_file",
        "description": "Read the contents of a file at the given path.",
        "parameters": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Absolute path to the file"
                },
                "offset": {
                    "type": "integer",
                    "description": "Line number to start reading from"
                },
                "limit": {
                    "type": "integer",
                    "description": "Number of lines to read"
                }
            },
            "required": ["path"]
        },
        "strict": True
    }
}]

# Step 2: Model decides to call the tool
response = client.chat.completions.create(
    model="gpt-4.1",
    messages=[{"role": "user", "content": "What does the main() function do in app.py?"}],
    tools=tools
)
# response.choices[0].message.tool_calls = [
#   { "function": { "name": "read_file", "arguments": '{"path": "app.py"}' } }
# ]

# Step 3: Application executes the function
file_content = read_file("app.py")

# Step 4: Return result to model
messages.append({"role": "tool", "content": file_content, "tool_call_id": "..."})

# Step 5: Model generates final answer
final = client.chat.completions.create(model="gpt-4.1", messages=messages, tools=tools)
```

### Key Technical Details

- **Tool definitions count as input tokens** — they are injected into the system prompt in a special format the model was trained to understand.
- Models are **fine-tuned specifically** to understand when to call functions and how to generate valid JSON arguments.
- **Parallel tool calls**: Modern models can request multiple function calls in a single turn (e.g., reading three files simultaneously).
- **Strict mode**: Ensures the model's JSON arguments conform exactly to the schema (no extra fields, correct types).
- **Function descriptions are critical** — they are the model's *only* understanding of what a tool does. Poorly described tools lead to poor usage.

### The Coding Agent Tool Kit

For coding agents specifically, the tool set typically includes:

| Category | Tools | Purpose |
|----------|-------|---------|
| **File I/O** | `read_file`, `write_file`, `edit_file`, `list_directory` | Navigate and modify the codebase |
| **Search** | `grep`, `glob`, `find_references`, `go_to_definition` | Discover relevant code |
| **Execution** | `run_command`, `run_tests`, `build` | Execute and validate code |
| **Web** | `web_search`, `fetch_url` | Access documentation and examples |
| **Planning** | `create_plan`, `update_task`, `todo_list` | Track multi-step work |
| **Sub-agents** | `spawn_agent`, `delegate_task` | Parallelize complex work |

**Sources**: [OpenAI Function Calling Guide](https://developers.openai.com/api/docs/guides/function-calling) · [Analytics Vidhya](https://www.analyticsvidhya.com/blog/2024/08/tool-calling-in-llms/)

---

## Layer 5: The Agentic Loop — ReAct and Beyond

### The Core Insight

A raw LLM with tool access can call one function and respond. But to solve real coding tasks, it needs to call tools **iteratively** — reading code, making edits, running tests, reading errors, fixing bugs, and repeating. This requires a **loop**.

### The ReAct Pattern

**ReAct** (Reasoning + Acting), introduced by Yao et al. (2022), is the foundational pattern for coding agents. The model **interleaves reasoning traces with actions** in a loop:

```
Thought 1: I need to understand the current code before making changes.
            Let me read the main file.
Action 1:  read_file("src/main.py")
Observation 1: [file contents...]

Thought 2: The bug is on line 42 — the comparison uses == instead of >=.
            I need to fix this and also update the test.
Action 2:  edit_file("src/main.py", line=42, old="==", new=">=")
Observation 2: File edited successfully.

Thought 3: Now let me run the tests to verify the fix.
Action 3:  run_command("pytest tests/ -v")
Observation 3: 15 passed, 0 failed.

Thought 4: All tests pass. The fix is correct.
Action 4:  [Final response to user]
```

### Why ReAct Works for Coding

| Component | Role in Coding |
|-----------|---------------|
| **Thought** | Plan the approach, diagnose errors, consider alternatives |
| **Action** | Read files, edit code, run commands, search |
| **Observation** | Receive file contents, command output, test results, error messages |

The key insight is that **reasoning without actions** leads to hallucination (the model invents plausible but wrong code), while **actions without reasoning** leads to random trial-and-error. ReAct combines both.

### The Agentic Loop in Practice

Every coding agent implements some variant of this loop:

```python
def agent_loop(user_request: str, tools: list, llm: LLM) -> str:
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_request}
    ]

    while True:
        # Ask the LLM what to do next
        response = llm.generate(messages, tools=tools)

        if response.has_tool_calls():
            # Execute each tool call
            for tool_call in response.tool_calls:
                result = execute_tool(tool_call.name, tool_call.arguments)
                messages.append({
                    "role": "tool",
                    "content": str(result),
                    "tool_call_id": tool_call.id
                })
        else:
            # No tool calls = agent is done
            return response.text
```

This is the **fundamental building block** of all coding agents. Claude Code calls it the "nO loop." SWE-Agent calls it the `forward()` method. GitHub Copilot's agent mode describes it as "iterating until reaching a final state." The names differ, but the pattern is universal.

### Variations on the Loop

| Pattern | Description | Used By |
|---------|-------------|---------|
| **Simple ReAct** | Single loop, one model | Claude Code, SWE-Agent |
| **Plan-then-Execute** | Generate a full plan first, then execute steps | Devin, MetaGPT |
| **Architect/Editor** | One model reasons, another edits code | Aider |
| **Hierarchical** | Lead agent delegates subtasks to sub-agents | Claude Research, OpenHands |
| **State Machine** | Finite-state transitions between defined phases | LangGraph agents |

**Sources**: [Yao et al., 2022](https://arxiv.org/abs/2210.03629) · [Prompt Engineering Guide](https://www.promptingguide.ai/techniques/react)

---

## Layer 6: Scaffolding, Memory, and Context Management

### What is Agent Scaffolding?

**Scaffolding** is the software architecture built *around* an LLM to enable it to perform complex, goal-driven tasks. It includes prompt templates, memory systems, tool interfaces, control flow, safety guardrails, and feedback mechanisms. The metaphor is apt: just as construction scaffolding supports a building under construction, agent scaffolding supports the LLM as it works.

### Memory Systems

Coding agents need memory that extends beyond the current context window:

#### Short-Term Memory (The Context Window)

The conversation history — all messages, tool calls, tool results, and reasoning traces — within the current context window. This is the agent's "working memory."

**Challenge: Context Bloat.** As the agent iterates, the context fills with irrelevant past errors, verbose file contents, and failed approaches. This increases cost, latency, and degrades reasoning quality.

#### Long-Term Memory

Mechanisms to persist information across and beyond context windows:

| Approach | Description | Used By |
|----------|-------------|---------|
| **Markdown files** | Simple text files storing project notes, conventions, and learned patterns | Claude Code (CLAUDE.md files) |
| **Vector databases** | Embedding-based retrieval of past interactions and code snippets | Cursor, some RAG-based agents |
| **Conversation summaries** | Compressed versions of past interactions | Claude Code's "Compressor wU2" |
| **Plan persistence** | Saving TODO lists and plans to disk | Claude Code (TodoWrite) |
| **Repository indexing** | Pre-computed index of codebase structure | Devin, Cursor |

### Context Management Strategies

The most critical engineering challenge in coding agents is **managing the finite context window**:

**Claude Code's approach**: "Compressor wU2" triggers at ~92% context utilization. It summarizes the conversation, preserves critical information (current task state, file locations, key decisions), and moves details to Markdown-based long-term storage. This is a pragmatic choice — simple files over complex vector databases — prioritizing reliability and debuggability.

**SWE-Agent's approach**: A `HistoryProcessor` compresses conversation history to fit context windows. It uses configurable retention policies to keep recent and relevant history while truncating older turns.

**Multi-agent approach** (Anthropic Research): Subagents operate in **separate context windows**, effectively multiplying the available context. Completed work is summarized before handoff. Fresh subagents with clean contexts can be spawned while maintaining continuity through structured summaries.

### Planning and Task Tracking

Complex coding tasks require explicit planning:

```json
// Claude Code's TodoWrite format
[
  { "id": "1", "content": "Read and understand the failing test", "status": "completed" },
  { "id": "2", "content": "Find the root cause in auth.py", "status": "in_progress" },
  { "id": "3", "content": "Implement the fix", "status": "pending" },
  { "id": "4", "content": "Run test suite to verify", "status": "pending" },
  { "id": "5", "content": "Check for regressions", "status": "pending" }
]
```

The current plan is injected as a system message after each tool use, keeping the agent oriented even as the context grows.

### Safety Guardrails

Production coding agents implement multiple safety layers:

- **Permission systems**: Separate approval tiers for read, write, and execute operations.
- **Command sanitization**: Risk-level classification for shell commands (safe: `ls`, `cat`; risky: `rm`, `sudo`).
- **Max iteration limits**: Prevent infinite loops (typically 20–50 turns).
- **Diff-first workflow**: Show proposed changes before applying them.
- **Sandboxing**: Run code in isolated Docker containers (SWE-Agent, OpenHands).
- **Kill switches**: Allow humans to abort runaway agents.

**Sources**: [ZBrain](https://zbrain.ai/agent-scaffolding/) · [ZenML](https://www.zenml.io/llmops-database/claude-code-agent-architecture-single-threaded-master-loop-for-autonomous-coding)

---

## Real-World Coding Agent Architectures

### Claude Code (Anthropic)

**Architecture**: Single-threaded master loop — deliberately simple.

```
User Input → System Prompt + Tools → Claude API → Tool Calls? 
    ├── Yes → Execute Tools → Append Results → Loop Back ↑
    └── No  → Return Text Response to User
```

**Design philosophy**: One flat message history, one main loop, no competing agent personas. Simplicity yields controllability.

**Key components**:
- **Tools**: `View`, `Edit`, `Write`, `Bash`, `Glob`, `GrepTool`, `LS`, `TodoWrite`, `Task` (sub-agent)
- **Context management**: Compressor at 92% utilization → Markdown long-term memory
- **Planning**: TodoWrite with JSON task lists injected as system messages
- **Sub-agents**: `Task` tool spawns independent agents with their own context windows for parallel work
- **Safety**: Tiered permission system, command risk classification

**Source**: [ZenML](https://www.zenml.io/llmops-database/claude-code-agent-architecture-single-threaded-master-loop-for-autonomous-coding) · [PromptLayer](https://blog.promptlayer.com/claude-code-behind-the-scenes-of-the-master-agent-loop/)

---

### GitHub Copilot Agent Mode

**Architecture**: Orchestrator with deep IDE integration.

**How it works**:
1. User provides a natural-language prompt in VS Code.
2. The prompt is augmented with workspace context (file structure, open files, diagnostics).
3. A system prompt instructs Copilot to **keep iterating until reaching a final state**.
4. Copilot reads files, edits code, runs terminal commands, and detects syntax errors, test failures, and build errors.
5. It course-corrects automatically based on feedback.

**Two modes**:
- **Agent Mode** (in-IDE): Synchronous pair programming — edits, runs, debugs in real time.
- **Coding Agent** (GitHub Actions): Asynchronous teammate — assign an issue, it creates a PR with full implementation.

**Extensibility**: Supports **MCP (Model Context Protocol)** servers for additional tool integration.

**Source**: [GitHub Blog](https://github.blog/ai-and-ml/github-copilot/agent-mode-101-all-about-github-copilots-powerful-mode/)

---

### SWE-Agent (Princeton University)

**Architecture**: LLM + Agent-Computer Interface (ACI) + Docker sandbox.

**Key innovation — the ACI**: An interface designed specifically for LLMs (not humans) to interact with computers:

- **Windowed file viewing**: Shows ~100 lines at a time. Research showed agents get overwhelmed by more, just as humans do.
- **Built-in linter**: Catches formatting errors immediately. 51.7% of SWE-Agent's edits had at least one error caught by the linter before submission.
- **Explicit feedback**: "Command ran successfully with no output" instead of empty responses.
- **Context indicators**: Current file, line number, and working directory shown with every command response.

**Components**: `SWEEnv` (Docker environment) → `Agent` (LLM orchestrator with `forward()` method) → `HistoryProcessor` (context compression) → `Parser` (action extraction)

**Performance**: Solved 12.5% of SWE-bench tickets (4× better than raw LLM prompting).

**Source**: [SWE-Agent Docs](https://swe-agent.com/latest/background/architecture/) · [Yang et al., 2024](https://arxiv.org/abs/2405.15793)

---

### Aider

**Architecture**: Terminal-based AI pair programmer with **Architect/Editor** separation.

**Key insight**: Separate code **reasoning** from code **editing** using two different models:

```
User Request → Architect Model (e.g., Claude Sonnet)
                  ↓ (high-level solution plan)
               Editor Model (e.g., GPT-4)
                  ↓ (precise code edits)
               Git Commit
```

1. **Architect model**: Focuses on problem-solving, algorithm selection, and solution design. Uses the full reasoning capabilities of frontier models.
2. **Editor model**: Translates the architect's plan into specific, correct code edits in the repository's existing style.

Works directly in **git repositories** — edits files and commits changes with meaningful messages. Over 80% of Aider's own codebase was written by Aider itself.

**Source**: [Aider Chat](https://aider.chat/2024/09/26/architect.html) · [GitHub: Aider](https://github.com/Aider-AI/aider)

---

### Devin (Cognition Labs)

**Architecture**: Fully autonomous AI software engineer with its own managed cloud environment.

- Has its own **code editor**, **web browser**, and **terminal** in a cloud sandbox.
- **Interactive planning**: Creates and updates plans as it works.
- **Repository indexing**: Automatically indexes codebases, generating architecture diagrams and docs.
- Handles multi-file changes, debugging, testing, and deployment end-to-end.

**Source**: [Devin.ai](https://devin.ai/) · [Cognition Blog](https://cognition.ai/blog/devin-2)

---

### OpenHands (formerly OpenDevin)

**Architecture**: Open-source platform with modular agent types and Docker sandboxing.

- **CodeAct Agent** (default): Uses code-based actions.
- **Browsing Agent**: Specialized for web research.
- Isolated Docker containers for all code execution.
- Multi-LLM support: OpenAI, Anthropic, open-source models via Ollama.

**Source**: [Wang et al., 2024](https://arxiv.org/abs/2407.16741)

---

### Cursor

**Architecture**: AI-native code editor (VS Code fork) with deep IDE integration.

- **Tab completion**: Inline suggestions with codebase awareness.
- **Chat**: Conversational coding with full context.
- **Agent mode**: Autonomous multi-step execution — reads files, edits code, runs terminals, uses web search, detects and fixes errors iteratively.

---

### Comparative Summary

| Agent | Loop Type | Sandboxing | Sub-agents | IDE Integration | Planning |
|-------|-----------|-----------|------------|----------------|----------|
| **Claude Code** | Simple while-loop | Optional | Yes (Task tool) | Terminal | TodoWrite JSON |
| **GitHub Copilot** | Orchestrator | VS Code terminal | No | Deep (VS Code) | Implicit |
| **SWE-Agent** | forward() + ACI | Docker | No | None (CLI) | Implicit in prompts |
| **Aider** | Architect/Editor | None | No | Terminal/git | Architect model |
| **Devin** | Plan-Execute | Cloud sandbox | Yes | Own IDE | Interactive plans |
| **OpenHands** | CodeAct loop | Docker | Multiple agent types | Web UI | Implicit |
| **Cursor** | IDE-integrated loop | Terminal | No | Deep (VS Code fork) | Implicit |

---

## Multi-Agent Orchestration

### Why Multi-Agent?

Single-agent systems hit fundamental limits:

- **Context window overflow**: Complex tasks produce more history than fits in one context.
- **Parallelism**: Many subtasks can be explored simultaneously.
- **Specialization**: Different agents optimized for different roles (coding, testing, reviewing, researching).
- **Information compression**: Each sub-agent distills findings into concise summaries.

### The Orchestrator-Worker Pattern

The most proven production pattern, used by Anthropic's Claude Research system:

```
                    ┌─────────────────┐
                    │   Lead Agent    │
                    │  (Orchestrator) │
                    │   Claude Opus   │
                    └────────┬────────┘
                             │ spawns
              ┌──────────────┼──────────────┐
              │              │              │
      ┌───────▼──────┐ ┌────▼─────┐ ┌──────▼───────┐
      │  Sub-agent 1 │ │ Sub-agent │ │  Sub-agent N │
      │  (Sonnet)    │ │ 2 (Sonnet)│ │  (Sonnet)    │
      │  Research    │ │ Code impl │ │  Testing     │
      └───────┬──────┘ └────┬─────┘ └──────┬───────┘
              │              │              │
              └──────────────┼──────────────┘
                             │ results
                    ┌────────▼────────┐
                    │   Lead Agent    │
                    │  (Synthesizes)  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Final Output   │
                    └─────────────────┘
```

**Results from Anthropic**: The multi-agent system with Opus lead + Sonnet workers **outperformed single-agent Opus by 90.2%** on internal research evaluations. Token usage explained **80%** of performance variance — multi-agent architectures effectively scale token usage by giving each sub-agent its own context window.

### Key Lessons from Production Multi-Agent Systems

1. **Teach the orchestrator to delegate well** — Each sub-agent needs a clear objective, output format, tool guidance, and task boundaries.
2. **Scale effort to query complexity** — Simple task = 1 agent with 3–10 tool calls. Complex task = 10+ sub-agents with parallel execution.
3. **Tool design is existential** — Agents with poorly described tools fail fundamentally. An Anthropic tool-testing agent that rewrote tool descriptions achieved a **40% decrease in task completion time**.
4. **Start wide, then narrow** — Explore broadly before drilling into specifics.
5. **Parallel tool calling** — Cut research time by up to **90%** for complex queries.

### Multi-Agent Frameworks

| Framework | Creator | Architecture |
|-----------|---------|-------------|
| **AutoGen** | Microsoft | Chatbot-style multi-agent conversations |
| **LangGraph** | LangChain | Graph-based stateful orchestration |
| **MetaGPT** | Academic | Agents simulate a software team (PM, Architect, Engineer, QA) |
| **CrewAI** | CrewAI | Task-focused role-based coordination |
| **Agent Development Kit** | Google | Formalized stateful orchestration |

**Source**: [Anthropic Engineering](https://www.anthropic.com/engineering/multi-agent-research-system)

---

## The Edit-Test-Debug Feedback Loop

The **defining capability** that separates a coding agent from a raw LLM is the ability to **iteratively refine** its output. The edit-test-debug loop is where theory meets practice:

```
┌──────┐     ┌──────┐     ┌──────┐     ┌─────────┐
│ PLAN │────>│ EDIT │────>│ TEST │────>│ OBSERVE │
└──────┘     └──────┘     └──────┘     └────┬────┘
   ▲                                        │
   │              ┌───────┐                 │
   └──────────────│ DEBUG │<────────────────┘
                  └───────┘
                (if errors)
```

### Evidence from Real Agent Behavior

Research on SWE-Agent's behavior across SWE-bench reveals a clear pattern:

| Phase | Turns | Dominant Actions |
|-------|-------|-----------------|
| **Understanding** | 1–2 | Search files, read code, navigate directory structure |
| **Initial implementation** | 2–5 | Edit files, run code to check changes |
| **Refinement** | 5–10 | Edit + run in tight loops, fixing errors |
| **Submission** | ~10 | Submit solution (if successful) |

**Key finding**: The fewer turns an agent takes, the more likely it succeeds. Getting stuck in long iteration loops is the most common failure mode.

### Self-Correction Strategies

Modern coding agents employ multiple self-correction mechanisms:

| Strategy | Description |
|----------|-------------|
| **Linter feedback** | Immediate syntactic error correction (catches 51.7% of errors in SWE-Agent) |
| **Test-driven development** | Run the test suite after each edit; use failures to guide the next edit |
| **Error message parsing** | Read compiler/runtime errors diagnostically to identify root causes |
| **Bug reproduction first** | Reproduce the bug before attempting a fix, then verify the fix resolves it |
| **Regression checking** | Ensure fixes don't break existing functionality |

### The Instruction Layer

Agents are guided by explicit instructions in their system prompts, mirroring advice a senior developer would give a junior:

- *"Always start by trying to replicate the bug."*
- *"If you run a command and it doesn't work, try a different command."*
- *"When you think you've fixed the bug, re-run the bug reproduction script."*
- *"When editing files, it is easy to accidentally specify a wrong line number."*

These instructions encode **software engineering wisdom** into the agent's behavior loop.

**Source**: [Pragmatic Engineer](https://newsletter.pragmaticengineer.com/p/ai-coding-agents)

---

## Key Takeaways and the Road Ahead

### The Six-Layer Stack

Every coding agent, from the simplest to the most sophisticated, is built on the same foundational stack:

1. **Raw LLM**: Next-token prediction provides the base capability to generate syntactically correct, semantically meaningful code.
2. **Prompt Engineering**: System prompts, few-shot examples, and structured output constraints make the LLM's output more reliable and predictable.
3. **Chain-of-Thought**: Explicit reasoning steps improve the model's ability to solve complex, multi-step coding problems.
4. **Tool Use**: Function calling transforms the model from a text generator into an agent that can read files, execute commands, and interact with the real world.
5. **Agentic Loop**: The ReAct pattern — think, act, observe, repeat — enables iterative problem-solving with self-correction.
6. **Multi-Agent Orchestration**: Coordinating multiple agents with separate contexts enables tackling problems too complex for any single agent.

### What Makes a Coding Agent Effective

The research reveals several consistent patterns across successful coding agents:

| Factor | Evidence |
|--------|----------|
| **Simple architecture** | Claude Code's single while-loop outperforms complex frameworks |
| **Well-designed tools** | SWE-Agent's ACI (100-line windows, linter integration) dramatically improves performance |
| **Iterative refinement** | The edit-test-debug loop, not one-shot generation, is what produces working code |
| **Context management** | Agents that manage their context well (compression, summarization, sub-agents) handle larger tasks |
| **Planning** | Explicit task tracking (TODO lists, plans) prevents agents from losing their way |
| **Token scaling** | More tokens ≈ better results — multi-agent systems scale token usage effectively |

### Open Challenges

- **Long-horizon tasks**: Agents still struggle with tasks requiring sustained coherence over hundreds of steps.
- **Codebase-scale reasoning**: Understanding the full architecture of a large codebase remains beyond current capabilities.
- **Specification ambiguity**: Agents often solve the wrong problem when requirements are vague.
- **Cost**: Multi-agent systems use 15× more tokens than chat — effective but expensive.
- **Evaluation**: Benchmarks (SWE-bench, HumanEval) don't fully capture real-world software engineering complexity.
- **Safety**: Autonomous code execution in production environments requires robust guardrails that don't exist yet at scale.

### The Trajectory

The trajectory is clear: coding agents are evolving from **assistants** (human-in-the-loop, single-turn) to **collaborators** (multi-turn, iterative) to **autonomous teammates** (asynchronous, task-to-PR). Each layer of the stack enables the next level of autonomy. The raw LLM provides the intelligence; everything built on top channels that intelligence into **reliable, safe, and effective software engineering**.

---

## References

1. Chen, M., et al. (2021). "Evaluating Large Language Models Trained on Code." *arXiv:2107.03374*. [Link](https://arxiv.org/abs/2107.03374)
2. Rozière, B., et al. (2023). "Code Llama: Open Foundation Models for Code." *Meta AI*. [Link](https://ai.meta.com/blog/code-llama-large-language-model-coding/)
3. Li, J., et al. (2023). "Structured Chain-of-Thought Prompting for Code Generation." *arXiv:2305.06599*. [Link](https://arxiv.org/abs/2305.06599)
4. Yao, S., et al. (2022). "ReAct: Synergizing Reasoning and Acting in Language Models." *arXiv:2210.03629*. [Link](https://arxiv.org/abs/2210.03629)
5. Yang, J., et al. (2024). "SWE-agent: Agent-Computer Interfaces Enable Automated Software Engineering." *arXiv:2405.15793*. [Link](https://arxiv.org/abs/2405.15793)
6. Wang, X., et al. (2024). "OpenHands: An Open Platform for AI Software Developers as Generalist Agents." *arXiv:2407.16741*. [Link](https://arxiv.org/abs/2407.16741)
7. OpenAI. "Function Calling Guide." *OpenAI API Documentation*. [Link](https://developers.openai.com/api/docs/guides/function-calling)
8. Anthropic. "How we built our multi-agent research system." *Anthropic Engineering Blog*. [Link](https://www.anthropic.com/engineering/multi-agent-research-system)
9. GitHub. "Agent mode 101: All about GitHub Copilot's agentic coding experience." *GitHub Blog*. [Link](https://github.blog/ai-and-ml/github-copilot/agent-mode-101-all-about-github-copilots-powerful-mode/)
10. ZenML. "Claude Code Agent Architecture: Single-Threaded Master Loop for Autonomous Coding." [Link](https://www.zenml.io/llmops-database/claude-code-agent-architecture-single-threaded-master-loop-for-autonomous-coding)
11. PromptLayer. "Claude Code: Behind the Scenes of the Master Agent Loop." [Link](https://blog.promptlayer.com/claude-code-behind-the-scenes-of-the-master-agent-loop/)
12. Pragmatic Engineer. "How do AI software engineering agents work?" [Link](https://newsletter.pragmaticengineer.com/p/ai-coding-agents)
13. ZBrain. "Agent Scaffolding Explained." [Link](https://zbrain.ai/agent-scaffolding/)
14. Prompt Engineering Guide. "ReAct Prompting." [Link](https://www.promptingguide.ai/techniques/react)
15. Aider. "Separating code reasoning and editing." [Link](https://aider.chat/2024/09/26/architect.html)
16. Towards Data Science. "Cracking the Code LLMs." [Link](https://towardsdatascience.com/cracking-the-code-llms-354505c53295/)

---

*Report generated February 2026. All citations verified at time of research.*
