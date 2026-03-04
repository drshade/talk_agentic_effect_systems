# Design: "Guardrails at the Speed of Thought: Effect Systems for Agentic Development"

**Date:** 2026-03-04
**Format:** 15-minute lightning talk + Marp slide deck (8 slides)
**Audience:** Internal team — senior engineers and data scientists, mixed FP/non-FP background

---

## Brief

From `BRIEF.md`:
- Language-agnostic framing, primary examples in Haskell + `effectful`
- Brief Python mention for self-research
- Three benefits: guardrails via architecture, reviewability via type-level effects, compiler as agent co-pilot
- Outputs: talk content + speaker notes, Marp markdown slide deck

---

## Title

**Primary:** *Guardrails at the Speed of Thought: Effect Systems for Agentic Development*

Alternatives considered:
- *Your Compiler Is Your Best Agent Reviewer*
- *Why Effect Systems Make AI Agents Less Terrifying*

---

## Narrative Arc (15 minutes)

| Segment | Duration | Purpose |
|---------|----------|---------|
| The Problem | ~2 min | Establish pain: agents are structurally blind, side effects invisible, architectural intent lost |
| What Are Effect Systems? | ~2 min | Accessible primer — effects in types, not implementation |
| Benefit 1: Architecture as Guardrails | ~3 min | Layered architecture enforced at compile time; agents constrained to valid moves |
| Benefit 2: Effects Taint | ~3 min | Reviewability — nothing sneaks through when effects surface in signatures |
| Benefit 3: Compiler as Co-Pilot | ~3 min | Type signatures are a dense, precise spec; agents can implement correctly from types alone |
| Other Ecosystems + Close | ~2 min | Python mention, resources, punchy closer |

---

## Slide Breakdown (8 slides)

### Slide 1 — Title
- Talk title, speaker name, date

### Slide 2 — The Problem
- 3 bullet pain points:
  - Agents write structurally blind code — they don't respect architectural layers
  - Side effects are invisible during code review
  - Architectural intent is lost in small context windows

### Slide 3 — What Are Effect Systems?
- Conceptual: effects declared in types, not buried in implementation
- One minimal illustrative Haskell type signature
- No prior FP knowledge assumed

### Slide 4 — Layered Architecture + Agents
- Diagram: `API Handlers → Domain Layer → Effects → Interpreters → [DB, Logging, External APIs]`
- Key point: the type system enforces layer boundaries — agents can only write valid code

### Slide 5 — Benefit 1: Guardrails
- Short Haskell snippet: domain function with effect constraint
- "The agent can't reach past this boundary without the compiler complaining"

### Slide 6 — Benefit 2: Effects Taint
- Short Haskell snippet: effects propagating in function signatures
- "Nothing sneaks through review — effects are visible at every call site"

### Slide 7 — Benefit 3: Compiler as Co-Pilot
- Type signatures *are* the spec
- Even with a small context window, types give the agent enough to implement correctly
- Optional: one concrete example of a type-driven agent prompt

### Slide 8 — Other Ecosystems + Close
- Python `effect` library (one-line mention)
- Pointers: Effect-TS, ZIO (Scala)
- Punchy closer: *"Structure your effects, control your agents."*

---

## Code Style

All snippets are abstract/illustrative — showing the *shape* of types, not complete working programs. Audience is intelligent; precision matters more than hand-holding.

Primary language: Haskell + `effectful`
Secondary: Python `effect` library (one snippet or mention only)

---

## Output Files

| File | Description |
|------|-------------|
| `talk/talk-notes.md` | Full talk content with speaker notes per section |
| `slides/slides.md` | Marp-formatted markdown slide deck |
