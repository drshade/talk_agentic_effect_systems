module Interpreters.Clock
  ( runClock
  ) where

import           Data.Time                  (getCurrentTime)
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effects.Clock              (Clock (..))

runClock :: IOE :> es => Eff (Clock : es) a -> Eff es a
runClock = interpret $ \_ -> \case
  Now -> liftIO getCurrentTime
