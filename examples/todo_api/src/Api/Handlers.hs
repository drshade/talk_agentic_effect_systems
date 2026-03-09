module Api.Handlers where

import           Api.Mapping         (parseId, toView)
import           Api.Types           (TodoView)
import           Architecture        (ApiEffects)

import           Data.Text           (Text)
import           Effectful
import           Effects.Logging     (logInfo)
import           Effects.TodoService (completeTodo, createTodo, getTodo,
                                      listTodos, removeTodo)

-- ── Request type ─────────────────────────────────────────────────────────────

newtype CreateTodoRequest = CreateTodoRequest { title :: Text }

-- ── Handlers ─────────────────────────────────────────────────────────────────

handleListTodos
  :: ApiEffects es
  => Eff es [TodoView]
handleListTodos = do
  logInfo "GET /todos"
  fmap toView <$> listTodos

handleCreateTodo
  :: ApiEffects es
  => CreateTodoRequest -> Eff es TodoView
handleCreateTodo req = do
  logInfo "POST /todos"
  toView <$> createTodo req.title

handleGetTodo
  :: ApiEffects es
  => Text -> Eff es (Maybe TodoView)
handleGetTodo rawId = do
  logInfo "GET /todos/:id"
  case parseId rawId of
    Nothing  -> pure Nothing
    Just tid -> fmap toView <$> getTodo tid

handleCompleteTodo
  :: ApiEffects es
  => Text -> Eff es (Maybe TodoView)
handleCompleteTodo rawId = do
  logInfo "PATCH /todos/:id/complete"
  case parseId rawId of
    Nothing  -> pure Nothing
    Just tid -> fmap toView <$> completeTodo tid

handleDeleteTodo
  :: ApiEffects es
  => Text -> Eff es Bool
handleDeleteTodo rawId = do
  logInfo "DELETE /todos/:id"
  case parseId rawId of
    Nothing  -> pure False
    Just tid -> removeTodo tid
