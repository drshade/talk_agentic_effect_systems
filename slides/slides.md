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
fetchUser
  :: (UserRepo :> es, Logging :> es)
  => UserId -> Eff es User
```

The compiler enforces that `fetchUser` can **only** read from `UserRepo` and write to `Logging`. Nothing more.

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

Each layer depends only on the layer below it. **Domain has no knowledge of infrastructure.** *...or does it have 5 layers?*

---

## Effects Encode Your Architecture

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

3 real layers. 2 interpreter boundaries. Use Cases and Ports were **never layers** — they're the translations between them.

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

## Structure your effects. Control your agents.

**Resources:**
- Haskell: [hackage.haskell.org/package/effectful](https://hackage.haskell.org/package/effectful)
- Python: [pypi.org/project/effect](https://pypi.org/project/effect/)
- TypeScript: [effect.website](https://effect.website/)
- Scala: [zio.dev](https://zio.dev/)
