module Effects.Logging
  ( Logging (..)
  , logInfo
  , logWarn
  , logError
  ) where

import           Data.Text    (Text)
import           Effectful
import           Effectful.TH (makeEffect)

data Logging :: Effect where
  LogInfo  :: Text -> Logging m ()
  LogWarn  :: Text -> Logging m ()
  LogError :: Text -> Logging m ()

makeEffect ''Logging
