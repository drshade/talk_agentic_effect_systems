module Entrypoints.Mapping
  ( toView
  , parseId
  ) where

import           Data.Text              (Text)
import qualified Data.UUID              as UUID
import           Domain.Todo            (Todo (..), TodoId (..))
import           Entrypoints.Types      (TodoView (..))

-- | Translate a domain Todo into an entrypoint view.
toView :: Todo -> TodoView
toView Todo {key = TodoId uuid, ..} =
  TodoView {id = UUID.toText uuid, ..}

-- | Parse a raw text parameter into a domain TodoId.
--   Failure to parse is an entrypoint concern — callers decide how to handle it.
parseId :: Text -> Maybe TodoId
parseId t = TodoId <$> UUID.fromText t
