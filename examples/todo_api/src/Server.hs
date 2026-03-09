-- | Servant HTTP server. Lifts the effect stack into Servant's Handler monad
--   via a natural transformation, then serves over Warp.
--
--   The handlers themselves are unchanged — they remain typed against
--   'EntrypointEffects' and know nothing about HTTP or Servant.
module Server
  ( run
  ) where

import           Application              (AppStack, runApp)
import           Control.Monad.IO.Class   (liftIO)
import           Data.Text                (Text)
import           Effectful                (Eff)
import           Entrypoints.Handlers
import           Entrypoints.Types        (TodoView)
import qualified Network.Wai.Handler.Warp as Warp
import           Servant

-- ── API type ─────────────────────────────────────────────────────────────────

type TodoAPI =
       "todos" :> Get '[JSON] [TodoView]
  :<|> "todos" :> ReqBody '[JSON] CreateTodoRequest :> Post '[JSON] TodoView
  :<|> "todos" :> Capture "id" Text :> Get '[JSON] (Maybe TodoView)
  :<|> "todos" :> Capture "id" Text :> "complete" :> Patch '[JSON] (Maybe TodoView)
  :<|> "todos" :> Capture "id" Text :> Delete '[JSON] Bool

todoAPI :: Proxy TodoAPI
todoAPI = Proxy

-- ── Server wiring ─────────────────────────────────────────────────────────────

-- | Lift an effectful computation into Servant's Handler via IO.
effToHandler :: FilePath -> Eff AppStack a -> Handler a
effToHandler dbPath = liftIO . runApp dbPath

todoServer :: FilePath -> Server TodoAPI
todoServer dbPath = hoistServer todoAPI (effToHandler dbPath) $
       handleListTodos
  :<|> handleCreateTodo
  :<|> handleGetTodo
  :<|> handleCompleteTodo
  :<|> handleDeleteTodo

-- | Start the HTTP server on the given port.
run :: FilePath -> Int -> IO ()
run dbPath port = Warp.run port (serve todoAPI (todoServer dbPath))
