module Domain.Todo where

import           Data.Text    (Text)
import           Data.Time    (UTCTime)
import           Data.UUID    (UUID)
import           GHC.Generics (Generic)

newtype TodoId = TodoId UUID
  deriving (Eq, Ord, Show, Generic)

data Todo = Todo
  { key       :: TodoId
  , title     :: Text
  , completed :: Bool
  , createdAt :: UTCTime
  , updatedAt :: UTCTime
  }
  deriving (Eq, Show, Generic)
