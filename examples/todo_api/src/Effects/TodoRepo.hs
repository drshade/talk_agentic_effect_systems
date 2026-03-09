module Effects.TodoRepo
  ( TodoRepo (..)
  , getAll
  , getById
  , insert
  , update
  , deleteById
  ) where

import           Domain.Todo  (Todo (..), TodoId)
import           Effectful
import           Effectful.TH (makeEffect)

data TodoRepo :: Effect where
  GetAll     :: TodoRepo m [Todo]
  GetById    :: TodoId -> TodoRepo m (Maybe Todo)
  Insert     :: Todo   -> TodoRepo m ()
  Update     :: Todo   -> TodoRepo m ()
  DeleteById :: TodoId -> TodoRepo m Bool

makeEffect ''TodoRepo
