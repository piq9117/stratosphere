module Spec.Golden (runGoldenTest) where

import Data.ByteString.Lazy
  ( ByteString,
    readFile,
    writeFile,
  )
import System.FilePath ((</>))
import Test.Hspec.Golden (Golden (..))
import Prelude hiding (readFile, writeFile)

runGoldenTest ::
  String ->
  ByteString ->
  Golden ByteString
runGoldenTest name actualOutput =
  Golden
    { output = actualOutput,
      encodePretty = show,
      writeToFile = writeFile,
      readFromFile = readFile,
      goldenFile = "test" </> "golden" </> name <> ".golden.json",
      actualFile = Just ("test" </> "golden" </> name <> ".actual.json"),
      failFirstTime = False
    }
