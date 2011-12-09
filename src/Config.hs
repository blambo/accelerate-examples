{-# LANGUAGE CPP, TemplateHaskell, PatternGuards #-}

module Config (

  Options, optBackend, optSize, optZoom, optScale, optDegree,
  processArgs, run

) where

import Data.Label
import System.Exit
import System.Console.GetOpt
import Data.Array.Accelerate                            ( Arrays, Acc )
import qualified Data.Array.Accelerate.Interpreter      as Interp
#ifdef ACCELERATE_CUDA_BACKEND
import qualified Data.Array.Accelerate.CUDA             as CUDA
#endif

data Backend = Interpreter
#ifdef ACCELERATE_CUDA_BACKEND
             | CUDA
#endif
  deriving (Bounded, Show)

data Options = Options
  {
    _optBackend :: Backend
  , _optSize    :: Int
  , _optZoom    :: Int
  , _optScale   :: Float
  , _optDegree  :: Int
  , _optHelp    :: Bool
  }
  deriving Show

$(mkLabels [''Options])

defaultOptions :: Options
defaultOptions = Options
  { _optBackend    = maxBound
  , _optSize       = 200
  , _optZoom       = 3
  , _optScale      = 30
  , _optDegree     = 5
  , _optHelp       = False
  }


run :: Arrays a => Options -> Acc a -> a
run opts = case _optBackend opts of
  Interpreter   -> Interp.run
#ifdef ACCELERATE_CUDA_BACKEND
  CUDA          -> CUDA.run
#endif


options :: [OptDescr (Options -> Options)]
options =
  [ Option []   ["interpreter"] (NoArg  (set optBackend Interpreter))   "reference implementation (sequential)"
#ifdef ACCELERATE_CUDA_BACKEND
  , Option []   ["cuda"]        (NoArg  (set optBackend CUDA))          "implementation for NVIDIA GPUs (parallel)"
#endif
  , Option []   ["size"]        (ReqArg (set optSize . read) "INT")     "visualisation size (default 200)"
  , Option []   ["zoom"]        (ReqArg (set optZoom . read) "INT")     "pixel replication factor (default 3)"
  , Option []   ["scale"]       (ReqArg (set optScale . read) "FLOAT")  "feature size of visualisation (default 30)"
  , Option []   ["degree"]      (ReqArg (set optDegree . read) "INT")   "number of waves to sum for each point (default 5)"
  , Option "h?" ["help"]        (NoArg  (set optHelp True))             "show help message"
  ]


processArgs :: [String] -> IO Options
processArgs argv =
  case getOpt' Permute options argv of
    (o,_,_,[])  -> case foldl (flip id) defaultOptions o of
                     opts | False <- get optHelp opts   -> return opts
                     _                                  -> putStrLn (helpMsg []) >> exitSuccess
    (_,_,_,err) -> error (helpMsg err)
  where
    helpMsg err = concat err ++ usageInfo header options
    header      = unlines
      [ "accelerate-crystal (c) 2011 The Accelerate Team"
      , ""
      , "Usage: accelerate-crystal [OPTIONS]"
      ]

