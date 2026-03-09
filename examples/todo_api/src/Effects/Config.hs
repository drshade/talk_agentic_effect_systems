module Effects.Config
  ( Config (..)
  , getDbPath
  ) where

import           Effectful
import           Effectful.TH (makeEffect)

-- | Read-only configuration. Kept as an effect so interpreters
--   downstream (e.g. tests) can swap in a different path without
--   touching any environment variables or global state.
data Config :: Effect where
  GetDbPath :: Config m FilePath

makeEffect ''Config
