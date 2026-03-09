-- | Architecture: the three-layer permission model for this application.
--
--   START HERE if you are adding a new feature.
--
-- = Codebase structure
--
--   * @Effects/@      — ports (interfaces only, no I\/O, no implementation).
--                       Each file declares an algebraic effect type and nothing else.
--                       Think of these as the contracts between layers.
--
--   * @Interpreters/@ — adapters (one per effect, contains all implementation detail).
--                       An interpreter eliminates one effect from the stack and may
--                       introduce others below it. Swap an interpreter to change the
--                       implementation without touching any other layer.
--
--   * Everything else — business logic and entrypoint code (handlers, domain types).
--                       These import from @Effects/@ only — never from @Interpreters/@.
--                       They describe /what/ to do, not /how/.
--
-- = Layer diagram
--
-- @
-- ┌─────────────────────────────────────────────────────────────────┐
-- │  Entrypoint Layer      (constraint: EntrypointEffects)          │
-- └──────────────────────────────┬──────────────────────────────────┘
--                                │  interpreter boundary
-- ┌──────────────────────────────▼──────────────────────────────────┐
-- │  Domain Layer             (constraint: DomainEffects)           │
-- └──────────────────────────────┬──────────────────────────────────┘
--                                │  interpreter boundary
-- ┌──────────────────────────────▼──────────────────────────────────┐
-- │  Infrastructure Layer     (constraint: InfraEffects)            │
-- └─────────────────────────────────────────────────────────────────┘
-- @
--
-- = How the constraints enforce the boundaries
--
--   Each layer is defined by a /constraint synonym/ below.
--   Use it as the constraint on every function belonging to that layer:
--
-- @
--   myHandler :: EntrypointEffects es => Input -> Eff es Output
-- @
--
--   Inside that function, @es@ is abstract — the compiler only knows what
--   the constraint requires. Any effect not listed in the synonym is a
--   compile error at the call site. The type system enforces the boundary;
--   manual discipline is not required.
--
-- = Adding a new effect (checklist)
--
--   1. Add @Effects\/MyEffect.hs@   — define the effect type and smart constructors.
--   2. Add @Interpreters\/MyEffect.hs@ — implement the interpreter.
--   3. Add the effect to @AppStack@ in @Application.hs@ (in the right position).
--   4. Add the corresponding @run*@ call to @runApp@ in @Application.hs@.
--   5. Add the effect to whichever constraint synonym(s) below need it.
module Architecture
  ( EntrypointEffects
  , DomainEffects
  , InfraEffects
  ) where

import           Effectful
import           Effects.Clock       (Clock)
import           Effects.Config      (Config)
import           Effects.IdGen       (IdGen)
import           Effects.Logging     (Logging)
import           Effects.TodoRepo    (TodoRepo)
import           Effects.TodoService (TodoService)

-- | Permission set for the __Entrypoint layer__.
--   Functions at this layer orchestrate high-level operations and produce
--   wire-friendly responses. They cannot perform I\/O or access lower-level
--   concerns directly — the types listed here are the only tools available.
type EntrypointEffects es =
  ( TodoService :> es
  , Logging     :> es
  )

-- | Permission set for the __Domain layer__.
--   Functions at this layer implement business logic using abstract ports.
--   No concrete I\/O, serialisation, or infrastructure details are reachable.
type DomainEffects es =
  ( TodoRepo :> es
  , Clock    :> es
  , IdGen    :> es
  , Logging  :> es
  )

-- | Permission set for the __Infrastructure layer__.
--   Functions at this layer perform real I\/O. This is the only layer
--   where @IOE@ appears — arbitrary I\/O is structurally absent above it.
type InfraEffects es =
  ( Config :> es
  , IOE    :> es
  )
