module Interpreters.TodoService
  ( runTodoService
  ) where

import           Architecture               (DomainEffects)
import           Domain.Todo                (Todo (..))
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effects.Clock              (now)
import           Effects.IdGen              (newId)
import           Effects.Logging            (logInfo)
import           Effects.TodoRepo           (deleteById, getAll, getById,
                                             insert, update)
import           Effects.TodoService        (TodoService (..))

-- | Eliminates TodoService from the effect stack.
--   Requires TodoRepo, Clock, IdGen, and Logging to already be present below —
--   those effects are provided by the outer interpreters in 'Application.runApp'.
runTodoService
  :: DomainEffects es
  => Eff (TodoService : es) a -> Eff es a
runTodoService = interpret $ \_ -> \case
  ListTodos -> do
    logInfo "listing todos"
    getAll

  CreateTodo title -> do
    logInfo $ "creating todo: " <> title
    key  <- newId
    now' <- now
    let todo = Todo {key, title, completed = False, createdAt = now', updatedAt = now'}
    insert todo
    pure todo

  GetTodo tid -> do
    logInfo "getting todo"
    getById tid

  CompleteTodo tid -> do
    logInfo "completing todo"
    getById tid >>= \case
      Nothing   -> pure Nothing
      Just todo -> do
        updatedAt <- now
        let done = todo { completed = True, updatedAt }
        update done
        pure (Just done)

  RemoveTodo tid -> do
    logInfo "removing todo"
    deleteById tid
