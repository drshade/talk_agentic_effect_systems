module Effects.IdGen
  ( IdGen (..)
  , newId
  ) where

import           Domain.Todo  (TodoId (..))
import           Effectful
import           Effectful.TH (makeEffect)

-- | ID generation as an effect. Without this, agents would reach for
--   `randomIO` or `nextRandom` inline inside domain logic, making
--   functions non-deterministic and untestable without knowing to look.
data IdGen :: Effect where
  NewId :: IdGen m TodoId

makeEffect ''IdGen
