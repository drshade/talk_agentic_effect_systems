module Api.Types
  ( TodoView (..)
  ) where

import           Data.Aeson   (ToJSON)
import           Data.Text    (Text)
import           Data.Time    (UTCTime)
import           GHC.Generics (Generic)

data TodoView = TodoView
  { id        :: Text
  , title     :: Text
  , completed :: Bool
  , createdAt :: UTCTime
  , updatedAt :: UTCTime
  }
  deriving (Show, Generic)
  deriving anyclass (ToJSON)
