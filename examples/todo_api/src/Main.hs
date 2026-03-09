-- | Entry point. Exercises the API through the full interpreter stack.
--   See Application.hs for the full interpreter stack and runApp definition.
module Main where

import           Api.Handlers
import           Api.Types    (TodoView (..))
import           Application  (runApp)
import           Effectful    (liftIO)

main :: IO ()
main = runApp "/tmp/todos.json" $ do
  -- Create
  t1 <- handleCreateTodo (CreateTodoRequest "Buy milk")
  t2 <- handleCreateTodo (CreateTodoRequest "Write talk slides")
  t3 <- handleCreateTodo (CreateTodoRequest "Deploy to production")

  -- List all
  todos <- handleListTodos
  liftIO $ putStrLn $ "\n=== " <> show (length todos) <> " todos ==="
  mapM_ (liftIO . print) todos

  -- t1.id :: Text — passed directly as a URL param would be
  _ <- handleCompleteTodo t1.id
  _ <- handleDeleteTodo   t2.id

  -- Final state
  final <- handleListTodos
  liftIO $ putStrLn $ "\n=== after complete + delete: " <> show (length final) <> " todos ==="
  mapM_ (liftIO . print) final

  -- GET by id
  result <- handleGetTodo t3.id
  liftIO $ putStrLn "\n=== GET /todos/:id ==="
  liftIO $ print result
