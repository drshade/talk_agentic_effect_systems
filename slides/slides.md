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

# Architecting Agentic Sandpits
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
fetchUser :: (UserRepo :> es, Logging :> es) => UserId -> Eff es User
```

The compiler enforces that `fetchUser` can **only** read from `UserRepo` and write to `Logging`. Nothing else.

---

## Worked example

```haskell
fetchUser :: (UserRepo :> es, Logging :> es) => UserId -> Eff es User
fetchUser userid = do
  log "Fetching user..."
  user <- lookupUser userid
  case user of
    Nothing -> ???? -- compiler won't allow us to fail
    Just user -> return user
```

```haskell
fetchUser :: (UserRepo :> es, Logging :> es, Error String :> es) => UserId -> Eff es User
fetchUser userid = do
  log "Fetching user..."
  user <- lookupUser userid
  case user of
    Nothing -> throwError "Unable to find user!" -- better 
    Just user -> return user
```

---

## Anatomy of effects

```haskell
-- design effects declaratively (just data)
data MyEffect :: Effect where
  DoSomething :: SomeInput -> MyEffect m SomeOutput

-- design how effects are handled (just functions)

-- eliminating the MyEffect type (unwrapping):
runMyEffect :: Eff (MyEffect : es) a -> Eff es a
runMyEffect = interpret $ \_ -> \case
  DoSomething input -> return ...

-- eliminating AND introducing another effect (re-wrapping):
runMyEffect :: (Logging :> es) => Eff (MyEffect : es) a -> Eff es a
runMyEffect = interpret $ \_ -> \case
  DoSomething input -> do
    log "hello"
    return ...
```

---

## A Well-Structured Backend

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

---

## Until it isn't...

```
┌──────────────────────────────────┐
│  API Handlers                    │  ─────────────────────────────────┐
│  routing · auth · serialisation  │  ──────────────────────┐          │
└───────────────┬──────────────────┘                        │          │
                ↓                                           ↓          │
┌───────────────▼──────────────────┐            Domain obj  │          │
│  Use Cases                       │            used direct │          │
│  workflows · orchestration       │                        │          │
└───────────────┬──────────────────┘                        │          │
                ↓                                           ↓          │
┌───────────────▼──────────────────┐  ◄─────────────────────┘          │
│  Domain                          │                                   │
│  entities · business rules       │                                   │
└───────────────┬──────────────────┘                                   │
                ↓                                                      │
┌───────────────▼──────────────────┐   ← Port skipped;                 │
│  Ports                           │     Infra called direct           │
│  abstract interfaces · no I/O    │                                   │
└───────────────┬──────────────────┘                                   │
                ↓                                                      │
┌───────────────▼──────────────────┐  ◄────────────────────────────────┘
│  Infrastructure                  │    API Handler calls DB direct
│  DB · email · external APIs      │
└──────────────────────────────────┘
```

---

## Effects Encode Your Architecture

```
┌──────────────────────────────────┐
│  API Handlers                    │
│  UserService :> es               │
└───────────────┬──────────────────┘
                │ Human governs Agent HERE!
                │ Use Cases Interpreter
                │ runUserService
┌───────────────▼──────────────────┐
│  Domain                          │
│  UserRepo :> es, Email :> es     │
└───────────────┬──────────────────┘
                │ Human governs Agent HERE!
                │ Ports Interpreter
                │ runUserRepo · runEmail
┌───────────────▼──────────────────┐
│  Infrastructure                  │
│  DB · email · external APIs      │
└──────────────────────────────────┘
```

---

## Benefit 1: Architecture as Guardrails

```haskell
-- Domain layer: an abstract effect interface
data UserService :: Effect where
  CreateUser :: NewUser -> UserService m User

-- API layer: only sees the interface
handleCreateUser
  :: (UserService :> es, Logging :> es)
  => CreateUserRequest -> Eff es UserResponse

-- Interpreter: eliminates UserService, introduces its deps
runUserService
  :: (UserRepo :> es, EmailNotification :> es)
  => Eff (UserService : es) a -> Eff es a
```

Above `runUserService`: `UserRepo` and `EmailNotification` don't exist.
The interpreter **is** the boundary.

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

**Your types are a dense, verified spec. Fit easily in any context window.**

---

## Other Ecosystems

| Language | Library | Notes |
|----------|---------|-------|
| Haskell | `effectful` | Strongest static guarantees |
| TypeScript | Effect-TS | Most accessible, large ecosystem |
| Scala | ZIO | Widely used in industry |
| Python | `effect` | Lighter, pragmatic |

---

## Appendix: Python `effect` Library

```python
from effect import Effect, sync_performer, TypeDispatcher

# Effects as data classes (the Ports)
class FetchUser:
    def __init__(self, user_id): self.user_id = user_id

class SendEmail:
    def __init__(self, to, body): self.to, self.body = to, body

# Business logic — yields effects, never touches I/O directly
def notify_user(user_id, message):
    user = yield Effect(FetchUser(user_id))
    yield Effect(SendEmail(user.email, message))

# Performer = interpreter (lives in infrastructure)
@sync_performer
def perform_fetch_user(_, intent):
    return db.session.get(User, intent.user_id)
```

No compile-time enforcement — but the same **structural discipline**.

---

## Appendix: TypeScript Effect-TS

```typescript
import { Effect, Context } from "effect"

// Define the service interface (the Port)
class UserRepo extends Context.Tag("UserRepo")<
  UserRepo,
  { fetchUser: (id: string) => Effect.Effect<User> }
>() {}

class EmailService extends Context.Tag("EmailService")<
  EmailService,
  { send: (to: string, body: string) => Effect.Effect<void> }
>() {}

// Business logic — pure, no I/O
const notifyUser = (userId: string, message: string) =>
  Effect.gen(function* () {
    const repo = yield* UserRepo
    const email = yield* EmailService
    const user = yield* repo.fetchUser(userId)
    yield* email.send(user.email, message)
  })

// Provide implementations at the boundary
notifyUser("123", "Hello").pipe(
  Effect.provideService(UserRepo, { fetchUser: dbFetchUser }),
  Effect.provideService(EmailService, { send: smtpSend }),
)
```

Compile-time enforced. **The closest TypeScript gets to Haskell's guarantees.**

---

## Further Reading: Effects

**Effects in other languages**
- [Koka](https://koka-lang.github.io) — language with row-polymorphic effects built in
- [OCaml 5 Effects](https://v2.ocaml.org/manual/effects.html) — native delimited continuations
- [Unison Abilities](https://www.unison-lang.org) — effects as first-class language feature

---

## Further Reading: Types, LLMs & Program Synthesis

**Some more exotic ideas**
- [ChopChop](https://arxiv.org/abs/2509.00360) — semantically constrain LLM output via coinductive type analysis
- [HYSYNTH](https://arxiv.org/abs/2405.15880) — context-free LLM approximation for program synthesis
- [SupGen / HVM4](https://github.com/HigherOrderCO/HVM) — exhaustive parallel program search via superposition nodes, collapsed by type signature

---

**Resources:**
- Haskell: [hackage.haskell.org/package/effectful](https://hackage.haskell.org/package/effectful)
- Python: [pypi.org/project/effect](https://pypi.org/project/effect/)
- TypeScript: [effect.website](https://effect.website/)
- Scala: [zio.dev](https://zio.dev/)
