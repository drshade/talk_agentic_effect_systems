module Interpreters.Config
  ( runConfig
  ) where

import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effects.Config             (Config (..))

runConfig :: FilePath -> Eff (Config : es) a -> Eff es a
runConfig dbPath = interpret $ \_ -> \case
  GetDbPath -> pure dbPath
