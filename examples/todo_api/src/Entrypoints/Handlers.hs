module Entrypoints.Handlers
  ( CreateTodoRequest (..)
  , handleListTodos
  , handleCreateTodo
  , handleGetTodo
  , handleCompleteTodo
  , handleDeleteTodo
  ) where

import           Architecture              (EntrypointEffects)
import           Data.Aeson                (FromJSON)
import           Data.Text                 (Text)
import           Effectful
import           Effects.Logging           (logInfo)
import           Effects.TodoService       (completeTodo, createTodo, getTodo,
                                            listTodos, removeTodo)
import           Entrypoints.Mapping       (parseId, toView)
import           Entrypoints.Types         (TodoView)
import           GHC.Generics              (Generic)

-- ── Request type ─────────────────────────────────────────────────────────────

newtype CreateTodoRequest = CreateTodoRequest { title :: Text }
  deriving (Generic)
  deriving anyclass (FromJSON)

-- ── Handlers ─────────────────────────────────────────────────────────────────

handleListTodos
  :: EntrypointEffects es
  => Eff es [TodoView]
handleListTodos = do
  logInfo "GET /todos"
  fmap toView <$> listTodos

handleCreateTodo
  :: EntrypointEffects es
  => CreateTodoRequest -> Eff es TodoView
handleCreateTodo req = do
  logInfo "POST /todos"
  toView <$> createTodo req.title

handleGetTodo
  :: EntrypointEffects es
  => Text -> Eff es (Maybe TodoView)
handleGetTodo rawId = do
  logInfo "GET /todos/:id"
  case parseId rawId of
    Nothing  -> pure Nothing
    Just tid -> fmap toView <$> getTodo tid

handleCompleteTodo
  :: EntrypointEffects es
  => Text -> Eff es (Maybe TodoView)
handleCompleteTodo rawId = do
  logInfo "PATCH /todos/:id/complete"
  case parseId rawId of
    Nothing  -> pure Nothing
    Just tid -> fmap toView <$> completeTodo tid

handleDeleteTodo
  :: EntrypointEffects es
  => Text -> Eff es Bool
handleDeleteTodo rawId = do
  logInfo "DELETE /todos/:id"
  case parseId rawId of
    Nothing  -> pure False
    Just tid -> removeTodo tid
