# Architecting Agentic Sandpits
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

---

## Section 3: Benefit 1 — Architecture as Guardrails (~3 min)

### Speaker Notes

Introduce the layered architecture first — this is probably familiar to most engineers in the room.

> "Most backend services have a layered architecture. At the top: API handlers — routing, auth, serialisation. Below that: use cases, which orchestrate business workflows. Then the domain — pure business logic, entities, rules, no I/O. Below that: ports, which are abstract interfaces for data access and external services. And at the bottom: infrastructure — the concrete implementations, the database, email, external APIs."

```
┌──────────────────────────────────┐
│  API Handlers                    │
│  routing · auth · serialisation  │
└───────────────┬──────────────────┘
                ↓
┌───────────────▼──────────────────┐
│  Use Cases                       │
│  workflows · orchestration       │
└───────────────┬──────────────────┘
                ↓
┌───────────────▼──────────────────┐
│  Domain                          │
│  entities · business rules       │
└───────────────┬──────────────────┘
                ↓
┌───────────────▼──────────────────┐
│  Ports                           │
│  abstract interfaces · no I/O    │
└───────────────┬──────────────────┘
                ↓
┌───────────────▼──────────────────┐
│  Infrastructure                  │
│  DB · email · external APIs      │
└──────────────────────────────────┘
```

> "The rule is simple: each layer only depends on the layer below it. The domain has no knowledge of infrastructure. API handlers never call the database directly. Most teams agree on this in principle."

> "But nothing enforces it. Linters help. Code review helps. They're after-the-fact. An agent writing a new feature will violate layer boundaries if the path of least resistance leads that way — and it often does."

Now the reveal. Point back at the previous slide.

> "We drew that as 5 layers. But let's apply an effect system and see what actually happens."

When you express this architecture in effects, Use Cases and Ports don't show up as layers — they show up as **interpreter boundaries**. They were never layers. They were always translations between layers. The types force you to be precise about this.

```
┌──────────────────────────────────┐
│  API Handlers                    │
│  UserService :> es               │
└───────────────┬──────────────────┘
                │ Use Cases Interpreter
                │ runUserService
                │ Handler → Domain mapping
┌───────────────▼──────────────────┐
│  Domain                          │
│  UserRepo :> es, Email :> es     │
└───────────────┬──────────────────┘
                │ Ports Interpreter
                │ runUserRepo · runEmail
                │ Domain → Infrastructure mapping
┌───────────────▼──────────────────┐
│  Infrastructure                  │
│  DB · email · external APIs      │
└──────────────────────────────────┘
```

> "3 real layers. 2 interpreter boundaries. Use Cases and Ports were never layers — they're the translations between them. Effect systems didn't change the architecture. They revealed what it always was."

Now show how effect systems enforce this. The key is that each layer communicates with the next via an **abstract effect interface**, not by calling functions directly. The domain layer is defined as an effect; interpreters are the boundaries between layers.

```haskell
-- 1. Define the domain layer as an abstract effect interface
data UserService :: Effect where
  CreateUser :: NewUser -> UserService m User

makeEffect ''UserService

-- 2. API layer: only sees the UserService interface
handleCreateUser
  :: (UserService :> es, Logging :> es)
  => CreateUserRequest -> Eff es UserResponse

-- 3. Interpreter: eliminates UserService, introduces its dependencies
runUserService
  :: (UserRepo :> es, EmailNotification :> es)
  => Eff (UserService : es) a -> Eff es a
```

> "The interpreter is the layer boundary. It consumes `UserService` from the effect row and introduces `UserRepo` and `EmailNotification` in its place. Above the interpreter — in the API layer — those infrastructure effects don't exist. An agent writing `handleCreateUser` cannot reach `UserRepo` because it's not in scope. The compiler won't allow it. The guardrail isn't a convention. It's structural."

Note: this also explains why effects taint *within* a layer but not *across* interpreter boundaries — the interpreter absorbs them.

### Key point to land

> "You write the architecture once, in types. Every agent that ever touches this codebase is constrained by it, forever, for free."

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
