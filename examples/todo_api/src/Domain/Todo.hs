-- | Core domain types. No I\/O, no serialisation, no framework dependencies.
--   Every other module that needs to reason about todos imports from here.
module Domain.Todo where

import           Data.Text    (Text)
import           Data.Time    (UTCTime)
import           Data.UUID    (UUID)
import           GHC.Generics (Generic)

-- | Opaque identifier for a todo item. Wraps a UUID to prevent accidental
--   mixing with raw UUIDs or other ID types at the type level.
newtype TodoId = TodoId UUID
  deriving (Eq, Ord, Show, Generic)

-- | A todo item. Named 'key' rather than 'id' to avoid shadowing 'Prelude.id'.
data Todo = Todo
  { key       :: TodoId  -- ^ Unique identifier
  , title     :: Text    -- ^ Human-readable description
  , completed :: Bool    -- ^ Whether the todo has been marked done
  , createdAt :: UTCTime -- ^ When the todo was first created
  , updatedAt :: UTCTime -- ^ When the todo was last modified
  }
  deriving (Eq, Show, Generic)
