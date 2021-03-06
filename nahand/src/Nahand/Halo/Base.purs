module Nahand.Halo.Base
  ( runBzEffect
  , NahandSettings
  , settings
  ) where

import Prelude
import Control.Monad.Aff (Aff)
import Control.Monad.Except (runExcept)
import Control.Monad.Except.Trans (ExceptT, runExceptT)
import Control.Monad.Reader.Trans (ReaderT, runReaderT)
import Servant.PureScript.Settings (SPSettings_(..), gDefaultToURLPiece)
import GenBzApi (SPParams_(..)) as Bz
import Data.Either (Either(..))
import Control.Monad.Eff.Console (log, CONSOLE)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class
import Servant.PureScript.Affjax (AjaxError)
import Network.HTTP.Affjax (AJAX)
import Data.Argonaut.Generic.Aeson (decodeJson, encodeJson)

type BzSettings = SPSettings_ Bz.SPParams_

data NahandSettings = NahandSettings { bzSettings :: BzSettings
                                     }
runEffect :: forall a eff s.
             s
          -> APIEffect eff s a
          -> Aff (ajax :: AJAX | eff) (Either AjaxError a)
runEffect st api = runExceptT $ runReaderT api st

runBzEffect :: forall a eff.
               NahandSettings
            -> BzEffect eff a
            -> Aff (ajax :: AJAX | eff) (Either AjaxError a)
runBzEffect (NahandSettings st) = runEffect (st.bzSettings)

log' :: forall eff m.
        (MonadEff (console :: CONSOLE | eff) m)
     => String
     -> m Unit
log' x = liftEff $ log x

settings :: NahandSettings
settings = NahandSettings { bzSettings : SPSettings_ { decodeJson : decodeJson
                                                     , encodeJson : encodeJson
                                                     , toURLPiece : gDefaultToURLPiece
                                                     , params : Bz.SPParams_ {
                                                       baseURL : "http://localhost:11000/" }
                                                     }
                          }

type APIEffect eff s = ReaderT s (ExceptT AjaxError (Aff (ajax :: AJAX | eff)))
type BzEffect eff = ReaderT BzSettings (ExceptT AjaxError (Aff (ajax :: AJAX | eff)))
