# Effect Systems Talk Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Produce a 15-minute lightning talk — speaker notes and an 8-slide Marp deck — on how effect systems improve agentic development.

**Architecture:** Two output files: `talk/talk-notes.md` (full prose + speaker notes) and `slides/slides.md` (Marp markdown). Content follows a Problem → Concept → Three Benefits → Close arc. Code snippets are abstract/illustrative Haskell + `effectful`, with a brief Python mention on the final slide.

**Tech Stack:** Marp (markdown slide renderer), Haskell `effectful` library (for snippets), Python `effect` library (brief mention)

---

## Reference: Design Doc

Full design rationale at `docs/plans/2026-03-04-effect-systems-agentic-talk-design.md`.

---

### Task 1: Create directory structure

**Files:**
- Create: `talk/talk-notes.md` (empty placeholder)
- Create: `slides/slides.md` (empty placeholder)

**Step 1: Create directories and placeholder files**

```bash
mkdir -p talk slides
touch talk/talk-notes.md slides/slides.md
```

**Step 2: Verify structure**

```bash
ls -R talk slides
```

Expected:
```
slides:
slides.md

talk:
talk-notes.md
```

**Step 3: Commit**

```bash
git add talk/ slides/
git commit -m "chore: scaffold talk and slides directories"
```

---

### Task 2: Write talk notes — The Problem section

**Files:**
- Modify: `talk/talk-notes.md`

This section sets up the pain. ~2 minutes of talk time. The goal is to make non-FP developers feel the problem before we offer a solution.

**Step 1: Write the Problem section**

Append to `talk/talk-notes.md`:

````markdown
# Guardrails at the Speed of Thought
## Effect Systems for Agentic Development

---

## Section 1: The Problem (~2 min)

### Speaker Notes

Open with a familiar scenario. Don't ask "has anyone used an LLM to write code?" — assume yes.

> "You describe a feature. The agent writes it. It compiles. The tests pass. You ship it. Two weeks later, something unexpected happens — a domain function is calling the database directly, a logging side effect is buried three layers deep, and nobody noticed during review because there was nothing to notice. The code *looked* fine."

Three structural problems with agent-generated code:

**1. Agents are architecturally blind.**
They write code that works, but they don't inherently respect your layered architecture. Without explicit structural constraints, an agent will reach across layers — calling DB adapters from domain logic, importing infrastructure from API handlers. It's not malicious; it just doesn't have a strong enough model of your intended structure.

**2. Side effects are invisible.**
In most codebases, a function signature tells you its inputs and outputs — but not its effects. Does it write to the database? Send an email? Call an external API? You can't tell from the type alone. Reviewing agent-generated code means reading every implementation, not just every signature.

**3. Context windows miss architectural intent.**
Even with large context windows, agents working on a big codebase are working with a lossy representation of its structure. They can see the file they're editing, nearby files, maybe some docs — but the *architecture* lives in the totality of the codebase, not any one view of it.

These three problems compound each other. The result: agent-generated code that is individually plausible but structurally brittle.
````

**Step 2: Review for clarity and timing**

Read aloud. Should take ~2 minutes. Trim if needed.

**Step 3: Commit**

```bash
git add talk/talk-notes.md
git commit -m "feat: add talk notes - problem section"
```

---

### Task 3: Write talk notes — What Are Effect Systems?

**Files:**
- Modify: `talk/talk-notes.md`

~2 minutes. Accessible primer — no prior FP knowledge assumed. Land the core idea: effects are declared in types.

**Step 1: Write the concept section**

Append to `talk/talk-notes.md`:

````markdown
---

## Section 2: What Are Effect Systems? (~2 min)

### Speaker Notes

Don't over-explain. One clear idea: effects are part of the type.

> "An effect system is a way of making side effects — database access, logging, network calls, randomness — visible in your type signatures. Instead of burying them in the implementation, you declare them as part of the function's type. The compiler then enforces that you only use the effects you've declared, and that you provide concrete implementations for them."

The key intuition: **a function's type becomes a complete description of what it does**, not just what it takes and returns.

In Haskell with the `effectful` library, a function that reads from a database and logs might look like:

```haskell
fetchUser :: (UserRepo :> es, Logging :> es) => UserId -> Eff es User
```

Read this as: "a function that, given a `UserId`, produces a `User` — and the only side effects it's permitted are reading from `UserRepo` and writing to `Logging`."

If the implementation tries to do anything else — send an email, write to the database directly — the compiler rejects it.

### Key point to land

> "The effects are not documentation. They are not a convention. They are enforced constraints. You cannot accidentally do more than you declared."

This is the foundation for everything that follows.
````

**Step 2: Commit**

```bash
git add talk/talk-notes.md
git commit -m "feat: add talk notes - effect systems concept section"
```

---

### Task 4: Write talk notes — Benefit 1: Architecture as Guardrails

**Files:**
- Modify: `talk/talk-notes.md`

~3 minutes. Show the layered architecture diagram in words, then show how the type system enforces it for agents.

**Step 1: Write Benefit 1 section**

Append to `talk/talk-notes.md`:

````markdown
---

## Section 3: Benefit 1 — Architecture as Guardrails (~3 min)

### Speaker Notes

Introduce the layered architecture first — this is probably familiar to most engineers in the room.

> "Most backend services have a layered architecture: API handlers at the top, domain logic in the middle, infrastructure at the bottom — databases, external APIs, logging. The rule is: each layer only depends on the layer below it. Domain logic should never import from the API layer. API handlers should never call the database directly."

```
API Handlers
     ↓
Domain Layer
     ↓
Effects (interfaces)
     ↓
Interpreters
     ↓
[DB] [Logging] [External APIs]
```

> "This is good architecture. Most teams agree on it in principle. But nothing enforces it. Linters help. Code review helps. But they're after-the-fact. An agent writing a new feature will violate layer boundaries if the path of least resistance leads that way — and it often does."

Now show how effect systems change this:

```haskell
-- API layer: can only use ApiEffect and Logging
handleCreateUser
  :: (ApiEffect :> es, Logging :> es)
  => CreateUserRequest -> Eff es UserResponse

-- Domain layer: can only use UserRepo and EmailNotification
createUser
  :: (UserRepo :> es, EmailNotification :> es)
  => NewUser -> Eff es User
```

> "If an agent writing `handleCreateUser` tries to call the database directly — bypassing the domain layer — the compiler refuses. `DbEffect` is not in the effect row. There is no way to express the violation in the type system. The guardrail isn't a suggestion. It's structural."

### Key point to land

> "You write the architecture once, in types. Every agent that ever touches this codebase is constrained by it, forever, for free."
````

**Step 2: Commit**

```bash
git add talk/talk-notes.md
git commit -m "feat: add talk notes - benefit 1 guardrails"
```

---

### Task 5: Write talk notes — Benefit 2: Effects Taint

**Files:**
- Modify: `talk/talk-notes.md`

~3 minutes. The reviewability argument. Effects propagate — you can't hide them. Code review becomes type-signature review.

**Step 1: Write Benefit 2 section**

Append to `talk/talk-notes.md`:

````markdown
---

## Section 4: Benefit 2 — Effects Taint (~3 min)

### Speaker Notes

> "Here's something subtle about effect systems: effects are contagious. If a function uses an effect, every function that calls it must also declare that effect — or provide an interpreter for it. You cannot call an effectful function from a pure context. The effect *taints* the call stack, all the way up."

This sounds like friction. It isn't. It's visibility.

Compare:

```haskell
-- Without effects: what does this actually do?
processOrder :: Order -> IO Result

-- With effects: the signature is a complete description
processOrder
  :: (PaymentGateway :> es, EmailNotification :> es, OrderRepo :> es)
  => Order -> Eff es Result
```

> "The second signature tells you everything. It touches payments, it sends emails, it writes to the order database. You know this from the type, before you read a single line of implementation. And because effects taint, you know that *every function that calls `processOrder`* also declares these effects — or swaps in a mock interpreter for testing."

For agent-generated code, this is transformative:

> "When an agent adds a new feature, any new effects it introduces surface immediately in the type. You can't sneak a database write into a function that wasn't supposed to touch the database. The diff doesn't just show you what code changed — it shows you what *effects* changed. Code review becomes effect review."

### Key point to land

> "You are not trusting the agent to respect your conventions. You are making it structurally impossible to violate them silently."
````

**Step 2: Commit**

```bash
git add talk/talk-notes.md
git commit -m "feat: add talk notes - benefit 2 effects taint"
```

---

### Task 6: Write talk notes — Benefit 3: Compiler as Co-Pilot

**Files:**
- Modify: `talk/talk-notes.md`

~3 minutes. The context window problem, and how types solve it. A well-typed architecture is a dense spec.

**Step 1: Write Benefit 3 section**

Append to `talk/talk-notes.md`:

````markdown
---

## Section 5: Benefit 3 — Compiler as Co-Pilot (~3 min)

### Speaker Notes

> "The third benefit is about what the agent *knows*. Context windows are large, but codebases are larger. When an agent writes a new function, it typically has access to the file it's editing, some nearby files, maybe a system prompt describing the architecture. It does not have perfect knowledge of the entire codebase."

> "In a loosely typed codebase, this means the agent is guessing. It infers conventions from examples, it tries to match patterns it's seen — and it gets things wrong in ways that are plausible but subtly inconsistent."

> "In an effect-typed codebase, the types themselves carry the architecture. Consider:"

```haskell
-- The agent receives this type signature to implement:
getUserOrderHistory
  :: (UserRepo :> es, OrderRepo :> es, Logging :> es)
  => UserId -> Eff es [Order]
```

> "From this signature alone, the agent knows: read from `UserRepo` to validate the user exists, read from `OrderRepo` to fetch their orders, log the operation. It knows which effects are in scope and which are not. It cannot introduce new effects without the type changing — and it knows the caller would then need to be updated too."

> "The type signature is a complete, machine-verified spec for the function. It's not documentation that can drift. It's not a convention that can be ignored. Every agent implementation attempt is type-checked against it."

A practical framing:

> "You can describe your entire architecture to an agent in a few dozen type signatures. That fits easily in any context window. The agent doesn't need to read your whole codebase — it needs to read your types."

### Key point to land

> "Types are a compression format for architectural intent. Effect types compress harder than most."
````

**Step 2: Commit**

```bash
git add talk/talk-notes.md
git commit -m "feat: add talk notes - benefit 3 compiler as co-pilot"
```

---

### Task 7: Write talk notes — Other Ecosystems + Close

**Files:**
- Modify: `talk/talk-notes.md`

~2 minutes. Broaden the picture briefly, then close strong.

**Step 1: Write closing section**

Append to `talk/talk-notes.md`:

````markdown
---

## Section 6: Other Ecosystems + Close (~2 min)

### Speaker Notes

> "Everything I've shown has been Haskell with the `effectful` library — that's my preference, and I think it's the cleanest expression of these ideas. But the concepts aren't Haskell-specific."

Brief mentions (one sentence each, no deep dive):

- **Python:** The `effect` library brings algebraic effects to Python. Less compile-time enforcement, but the same architectural discipline. Worth looking at if your team is Python-native.
- **TypeScript:** Effect-TS is a serious, production-ready effect system for TypeScript with a large ecosystem.
- **Scala:** ZIO is the dominant effect system in the Scala world, widely used in industry.

> "The tradeoffs vary. Haskell gives you the strongest static guarantees. TypeScript's Effect-TS is probably the most accessible if you're coming from a mainstream OO background. Python's `effect` library is lighter and more pragmatic."

### Close

> "We talk a lot about how to prompt agents better, how to review their output more carefully, how to catch their mistakes. I want to suggest a different frame: make their mistakes structurally impossible. Define your architecture in types. Declare your effects. Let the compiler be the reviewer that never gets tired, never misses a boundary violation, and never needs to be on the same team as the agent to enforce your rules."

> "Structure your effects. Control your agents."

---

## Resources

- [effectful (Haskell)](https://hackage.haskell.org/package/effectful)
- [effect (Python)](https://pypi.org/project/effect/)
- [Effect-TS](https://effect.website/)
- [ZIO (Scala)](https://zio.dev/)
````

**Step 2: Commit**

```bash
git add talk/talk-notes.md
git commit -m "feat: add talk notes - closing section and resources"
```

---

### Task 8: Write Marp slide deck

**Files:**
- Modify: `slides/slides.md`

8 slides. Marp format. Minimal text per slide — the talk notes carry the detail. Code snippets are the same ones from the talk notes, formatted for slides.

**Step 1: Write the full slide deck**

Write the following to `slides/slides.md`:

````markdown
---
marp: true
theme: default
paginate: true
style: |
  section {
    font-family: 'JetBrains Mono', monospace, sans-serif;
  }
  code {
    font-size: 0.8em;
  }
  h1 { color: #1a1a2e; }
  h2 { color: #16213e; }
---

# Guardrails at the Speed of Thought
## Effect Systems for Agentic Development

---

## The Problem

- Agents are **architecturally blind** — they don't respect layers
- Side effects are **invisible** in function signatures
- Context windows miss **architectural intent**

> These problems compound. Individually plausible code; structurally brittle systems.

---

## What Are Effect Systems?

Effects declared **in the type** — not buried in the implementation.

```haskell
fetchUser
  :: (UserRepo :> es, Logging :> es)
  => UserId -> Eff es User
```

The compiler enforces that `fetchUser` can **only** read from `UserRepo` and write to `Logging`. Nothing more.

---

## Layered Architecture

```
API Handlers
     ↓
Domain Layer
     ↓
Effects  ←  declared interfaces
     ↓
Interpreters
     ↓
[DB]  [Logging]  [External APIs]
```

Each layer's permitted effects are declared in its types.

---

## Benefit 1: Architecture as Guardrails

```haskell
-- API layer
handleCreateUser
  :: (ApiEffect :> es, Logging :> es)
  => CreateUserRequest -> Eff es UserResponse

-- Domain layer
createUser
  :: (UserRepo :> es, EmailNotification :> es)
  => NewUser -> Eff es User
```

An agent writing `handleCreateUser` **cannot** call `DbEffect` directly.
The compiler rejects it. The guardrail is structural.

---

## Benefit 2: Effects Taint

```haskell
-- What does this do? ¯\_(ツ)_/¯
processOrder :: Order -> IO Result

-- This tells you everything
processOrder
  :: (PaymentGateway :> es, EmailNotification :> es, OrderRepo :> es)
  => Order -> Eff es Result
```

Effects propagate. You can't hide them. **Code review becomes effect review.**

---

## Benefit 3: Compiler as Co-Pilot

```haskell
getUserOrderHistory
  :: (UserRepo :> es, OrderRepo :> es, Logging :> es)
  => UserId -> Eff es [Order]
```

From this signature, an agent knows:
- Which effects are in scope
- What it's allowed to do
- What would break the type if added

**Your types are a dense, verified spec. They fit in any context window.**

---

## Other Ecosystems

| Language | Library | Notes |
|----------|---------|-------|
| Haskell | `effectful` | Strongest static guarantees |
| TypeScript | Effect-TS | Most accessible, large ecosystem |
| Scala | ZIO | Widely used in industry |
| Python | `effect` | Lighter, pragmatic |

---

## Structure your effects. Control your agents.

**Resources:**
- Haskell: [hackage.haskell.org/package/effectful](https://hackage.haskell.org/package/effectful)
- Python: [pypi.org/project/effect](https://pypi.org/project/effect/)
- TypeScript: [effect.website](https://effect.website/)
````

**Step 2: Verify Marp can parse the file (if Marp CLI is available)**

```bash
# If marp CLI is installed:
marp --version && marp slides/slides.md --dry-run
# If not installed, skip — the markdown is valid Marp syntax
```

**Step 3: Commit**

```bash
git add slides/slides.md
git commit -m "feat: add Marp slide deck"
```

---

### Task 9: Final review pass

**Files:**
- Read: `talk/talk-notes.md`
- Read: `slides/slides.md`

**Step 1: Cross-check talk notes against slides**

Verify:
- Every slide has a corresponding section in the talk notes
- Code snippets match exactly between the two files
- Timing adds up to ~15 minutes (6 sections: 2+2+3+3+3+2)
- Resources section matches in both files

**Step 2: Check slide count**

```bash
grep -c "^---" slides/slides.md
```

Expected: 9 (8 slide separators + front-matter separator = 9 `---` occurrences)

**Step 3: Commit any corrections**

```bash
git add talk/talk-notes.md slides/slides.md
git commit -m "fix: final review pass - cross-check notes and slides"
```

---

## Output Summary

| File | Description |
|------|-------------|
| `talk/talk-notes.md` | Full speaker notes, ~15 min talk |
| `slides/slides.md` | 8-slide Marp deck |
| `docs/plans/2026-03-04-effect-systems-agentic-talk-design.md` | Design document |
| `docs/plans/2026-03-04-effect-systems-talk.md` | This plan |
