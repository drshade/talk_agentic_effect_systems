module Interpreters.Logging
  ( runLogging
  ) where

import qualified Data.Text.IO               as TIO
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effects.Logging            (Logging (..))

runLogging :: IOE :> es => Eff (Logging : es) a -> Eff es a
runLogging = interpret $ \_ -> \case
  LogInfo  msg -> liftIO $ TIO.putStrLn $ "[INFO]  " <> msg
  LogWarn  msg -> liftIO $ TIO.putStrLn $ "[WARN]  " <> msg
  LogError msg -> liftIO $ TIO.putStrLn $ "[ERROR] " <> msg
