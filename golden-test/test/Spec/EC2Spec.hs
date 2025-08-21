module Spec.EC2Spec (spec) where

import Data.Text (Text)
import Spec.Golden (runGoldenTest)
import Stratosphere (Parameter (..), Template (..))
import qualified Stratosphere
import Stratosphere.EC2.Instance (Instance (..))
import qualified Stratosphere.EC2.Instance
import Test.Hspec (Spec, describe, it)
import Prelude

template :: Stratosphere.Template
template =
  (Stratosphere.mkTemplate [ec2Instance])
    { description = Just "EC2 Example template",
      parameters = Just [keyName]
    }

keyName :: Stratosphere.Parameter
keyName =
  (Stratosphere.mkParameter "KeyName" "AWS::EC2::KeyPair::KeyName")
    { description = Just "Name of an existing EC2 KeyPair to enable SSH access to the instance",
      constraintDescription = Just "Must be the name of an existing EC2 KeyPair"
    }

ec2Instance :: Stratosphere.Resource
ec2Instance =
  Stratosphere.resource @Stratosphere.EC2.Instance.Instance
    "EC2Instance"
    ( Stratosphere.EC2.Instance.mkInstance
        { imageId = Just "ami-22111148",
          keyName = Just (Stratosphere.toRef @Stratosphere.Parameter @Text keyName)
        }
    )

spec :: Spec
spec =
  describe "EC2GoldenTests" $ do
    it "EC2 Template" $ do
      runGoldenTest "ec2" (Stratosphere.encodeTemplate template)
