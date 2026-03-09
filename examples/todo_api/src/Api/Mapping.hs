
module Api.Mapping
  ( toView
  , parseId
  ) where

import           Api.Types   (TodoView (..))
import           Data.Text   (Text)
import qualified Data.UUID   as UUID
import           Domain.Todo (Todo (..), TodoId (..))

-- | Translate a domain Todo into an API view.
toView :: Todo -> TodoView
toView Todo {key = TodoId uuid, ..} =
  TodoView {id = UUID.toText uuid, ..}

-- | Parse a raw URL parameter into a domain TodoId.
--   Failure to parse is an API-layer concern — callers decide how to handle it.
parseId :: Text -> Maybe TodoId
parseId t = TodoId <$> UUID.fromText t
