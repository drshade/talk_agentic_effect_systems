module Main where

import           Application          (runApp)
import           Data.Text            (Text)
import           Effectful            (liftIO)
import           Entrypoints.Handlers
import           Entrypoints.Types    (TodoView)
import           Options.Applicative
import qualified Server

-- ── Command model ─────────────────────────────────────────────────────────────

data GlobalOpts = GlobalOpts
  { dbPath :: FilePath
  , cmd    :: Command
  }

data Command
  = Serve   { port    :: Int  }
  | List
  | Create  { todoTitle :: Text }
  | Get     { todoId    :: Text }
  | Complete{ todoId    :: Text }
  | Delete  { todoId    :: Text }

-- ── Parsers ───────────────────────────────────────────────────────────────────

globalOpts :: Parser GlobalOpts
globalOpts = GlobalOpts
  <$> strOption
        ( long "db" <> metavar "PATH"
        <> value "/tmp/todos.json" <> showDefault
        <> help "Path to the JSON database file" )
  <*> subparser
        ( command "serve"
            (info serveCmd    (progDesc "Start the HTTP server"))
        <> command "list"
            (info listCmd     (progDesc "List all todos"))
        <> command "create"
            (info createCmd   (progDesc "Create a new todo"))
        <> command "get"
            (info getCmd      (progDesc "Get a todo by ID"))
        <> command "complete"
            (info completeCmd (progDesc "Mark a todo as complete"))
        <> command "delete"
            (info deleteCmd   (progDesc "Delete a todo"))
        )

serveCmd :: Parser Command
serveCmd = Serve
  <$> option auto
        ( long "port" <> short 'p'
        <> value 8080 <> showDefault
        <> help "Port to listen on" )

listCmd    :: Parser Command
listCmd    = pure List

createCmd  :: Parser Command
createCmd  = Create <$> argument str (metavar "TITLE")

getCmd     :: Parser Command
getCmd     = Get <$> argument str (metavar "ID")

completeCmd :: Parser Command
completeCmd = Complete <$> argument str (metavar "ID")

deleteCmd  :: Parser Command
deleteCmd  = Delete <$> argument str (metavar "ID")

-- ── Entry point ───────────────────────────────────────────────────────────────

main :: IO ()
main = do
  opts <- execParser
    (info (globalOpts <**> helper)
          (fullDesc <> progDesc "Todo API — HTTP server and CLI"))
  case opts.cmd of
    Serve port    -> Server.run opts.dbPath port
    List          -> runApp opts.dbPath $ do
                       todos <- handleListTodos
                       liftIO $ mapM_ print todos
    Create title  -> runApp opts.dbPath $ do
                       todo <- handleCreateTodo (CreateTodoRequest title)
                       liftIO $ print (todo :: TodoView)
    Get    tid    -> runApp opts.dbPath $ do
                       result <- handleGetTodo tid
                       liftIO $ print (result :: Maybe TodoView)
    Complete tid  -> runApp opts.dbPath $ do
                       result <- handleCompleteTodo tid
                       liftIO $ print (result :: Maybe TodoView)
    Delete  tid   -> runApp opts.dbPath $ do
                       ok <- handleDeleteTodo tid
                       liftIO $ print ok
