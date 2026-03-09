module Effects.TodoService
  ( TodoService (..)
  , listTodos
  , createTodo
  , getTodo
  , completeTodo
  , removeTodo
  ) where

import           Data.Text    (Text)
import           Domain.Todo  (Todo, TodoId)
import           Effectful
import           Effectful.TH (makeEffect)

-- | The service interface visible to the API layer.
--   API handlers see *only* this — not TodoRepo, Clock, or IdGen.
data TodoService :: Effect where
  ListTodos    :: TodoService m [Todo]
  CreateTodo   :: Text   -> TodoService m Todo
  GetTodo      :: TodoId -> TodoService m (Maybe Todo)
  CompleteTodo :: TodoId -> TodoService m (Maybe Todo)
  RemoveTodo   :: TodoId -> TodoService m Bool

makeEffect ''TodoService
