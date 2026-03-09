-- | Concrete application wiring: the full effect stack and the top-level runner.
--
--   See "Architecture" for the layer diagram, constraint synonyms, and the
--   checklist for adding a new effect.
module Application
  ( -- * Full effect stack
    -- | The concrete list of all effects in the application, outermost first.
    --   Handlers receive this stack and see only what EntrypointEffects permits.
    AppStack
    -- * Application runner
  , runApp
  ) where

import           Effectful
import           Effects.Clock            (Clock)
import           Effects.Config           (Config)
import           Effects.IdGen            (IdGen)
import           Effects.Logging          (Logging)
import           Effects.TodoRepo         (TodoRepo)
import           Effects.TodoService      (TodoService)
import           Interpreters.Clock       (runClock)
import           Interpreters.Config      (runConfig)
import           Interpreters.IdGen       (runIdGen)
import           Interpreters.Logging     (runLogging)
import           Interpreters.TodoRepo    (runTodoRepo)
import           Interpreters.TodoService (runTodoService)

-- | The full concrete effect stack, outermost-first.
--   Each entry is eliminated by its corresponding interpreter in runApp.
type AppStack =
  '[ TodoService  -- eliminated by runTodoService
   , TodoRepo     -- eliminated by runTodoRepo
   , IdGen        -- eliminated by runIdGen
   , Clock        -- eliminated by runClock
   , Config       -- eliminated by runConfig
   , Logging      -- eliminated by runLogging
   , IOE          -- eliminated by runEff
   ]

-- | Wire the full interpreter stack.
--   Each line is a layer boundary: an interpreter that eliminates
--   one layer's effects and introduces the effects below.
runApp :: FilePath -> Eff AppStack a -> IO a
runApp dbPath =
    runEff
  . runLogging
  . runConfig dbPath
  . runClock
  . runIdGen
  . runTodoRepo
  . runTodoService
