module Effects.Clock
  ( Clock (..)
  , now
  ) where

import           Data.Time    (UTCTime)
import           Effectful
import           Effectful.TH (makeEffect)

-- | Abstracting over time means agents can never bury `getCurrentTime`
--   in domain logic without it appearing in the effect row.
data Clock :: Effect where
  Now :: Clock m UTCTime

makeEffect ''Clock
