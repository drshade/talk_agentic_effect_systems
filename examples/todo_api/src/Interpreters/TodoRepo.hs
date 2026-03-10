module Interpreters.TodoRepo
  ( runTodoRepo
  ) where

import           Data.Aeson                 (FromJSON, ToJSON)
import qualified Data.Aeson                 as Aeson
import qualified Data.ByteString            as BS
import qualified Data.ByteString.Lazy       as LBS
import           Data.List                  (find, partition)
import           Data.Maybe                 (mapMaybe)
import           Data.Text                  (Text)
import           Data.Time                  (UTCTime)
import qualified Data.UUID                  as UUID
import           Domain.Todo                (Todo (..), TodoId (..))
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effects.Config             (Config, getDbPath)
import           Effects.TodoRepo           (TodoRepo (..))
import           GHC.Generics               (Generic)
import           System.Directory           (doesFileExist)

-- | Interpret TodoRepo against a JSON file on disk.
--   Eliminates TodoRepo; introduces Config and IOE.
runTodoRepo :: (Config :> es, IOE :> es) => Eff (TodoRepo : es) a -> Eff es a
runTodoRepo = interpret $ \_ -> \case
  GetAll -> do
    stored <- getDbPath >>= readDb
    pure $ mapMaybe toDomain stored

  GetById tid -> do
    stored <- getDbPath >>= readDb
    pure $ find (\t -> t.key == tid) (mapMaybe toDomain stored)

  Insert todo -> do
    path   <- getDbPath
    stored <- readDb path
    writeDb path (fromDomain todo : stored)

  Update todo -> do
    path   <- getDbPath
    stored <- readDb path
    let s = fromDomain todo
    writeDb path $ map (\r -> if r.key == s.key then s else r) stored

  DeleteById tid -> do
    path   <- getDbPath
    stored <- readDb path
    let textKey         = UUID.toText (let TodoId u = tid in u)
        (deleted, kept) = partition (\s -> s.key == textKey) stored
    writeDb path kept
    pure (not $ null deleted)

-- ── Storage representation ────────────────────────────────────────────────────

data StoredTodo = StoredTodo
  { key       :: Text
  , title     :: Text
  , completed :: Bool
  , createdAt :: UTCTime
  , updatedAt :: UTCTime
  }
  deriving (Show, Generic)
  deriving anyclass (FromJSON, ToJSON)

fromDomain :: Todo -> StoredTodo
fromDomain Todo {key = TodoId uuid, ..} = StoredTodo {key = UUID.toText uuid, ..}

toDomain :: StoredTodo -> Maybe Todo
toDomain StoredTodo {key = keyText, ..} = do
  uuid <- UUID.fromText keyText
  pure Todo {key = TodoId uuid, ..}

-- ── I/O helpers ───────────────────────────────────────────────────────────────

readDb :: IOE :> es => FilePath -> Eff es [StoredTodo]
readDb path = liftIO $ do
  exists <- doesFileExist path
  if not exists
    then pure []
    else do
      bytes <- BS.readFile path
      pure $ case Aeson.decodeStrict' @[StoredTodo] bytes of
        Just todos -> todos
        Nothing    -> []

writeDb :: IOE :> es => FilePath -> [StoredTodo] -> Eff es ()
writeDb path todos = liftIO $ LBS.writeFile path (Aeson.encode todos)
