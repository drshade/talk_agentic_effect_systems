module Interpreters.IdGen
  ( runIdGen
  ) where

import           Data.UUID.V4               (nextRandom)
import           Domain.Todo                (TodoId (..))
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effects.IdGen              (IdGen (..))

runIdGen :: IOE :> es => Eff (IdGen : es) a -> Eff es a
runIdGen = interpret $ \_ -> \case
  NewId -> TodoId <$> liftIO nextRandom
