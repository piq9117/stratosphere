module Spec.SimpleLambdaSpec (spec) where

import Data.Aeson (Object, Value (..), object)
import Data.Text (Text)
import Spec.Golden (runGoldenTest)
import Stratosphere (Template (..))
import qualified Stratosphere
import Stratosphere.IAM.Role (Role (..))
import qualified Stratosphere.IAM.Role
import Stratosphere.Lambda.Function (CodeProperty (..), Function (..))
import qualified Stratosphere.Lambda.Function
import Test.Hspec (Spec, describe, it)
import Prelude

template :: Stratosphere.Template
template =
  let Stratosphere.Template {..} = Stratosphere.mkTemplate [role, lambda]
   in Stratosphere.Template
        { description = Just "Lambda example",
          ..
        }

lambda :: Stratosphere.Resource
lambda =
  Stratosphere.resource
    "LambdaFunction"
    ( ( Stratosphere.Lambda.Function.mkFunction
          lambdaCode
          (Stratosphere.GetAtt "IAMRole" "Arn")
      )
        { handler = Just "index.handler",
          runtime = Just "nodejs12.x"
        }
    )
  where
    lambdaCode =
      Stratosphere.Lambda.Function.mkCodeProperty
        { zipFile = Just code
        }

    code :: Stratosphere.Value Text
    code =
      "\
      \ exports.handler = function(event, context, callback) { \
      \  console.log(\"value1 = \" + event.key1); \
      \  console.log(\"value2 = \" + event.key2); \
      \  callback(null, \"some success message\"); \
      \ } \
      \ "

role :: Stratosphere.Resource
role =
  ( Stratosphere.resource
      "IAMRole"
      ( Stratosphere.IAM.Role.mkRole rolePolicyDocumentObject
      )
        { policies = Just [executePolicy],
          roleName = Just "MyLambdaBasicExecutionRole",
          path = Just "/"
        }
  )
  where
    rolePolicyDocumentObject :: Object
    rolePolicyDocumentObject =
      [ ("Version", "2012-10-17"),
        ( "Statement",
          object
            [ ("Effect", "Allow"),
              ("Principal", Object [("Service", "lambda.amazonaws.com")]),
              ("Action", "sts:AssumeRole")
            ]
        )
      ]
    executePolicy =
      Stratosphere.IAM.Role.mkPolicyProperty
        [ ("Version", "2012-10-17"),
          ( "Statement",
            object
              [ ("Effect", "Allow"),
                ( "Action",
                  Array
                    [ "logs:CreateLogGroup",
                      "logs:CreateLogStream",
                      "logs:PutLogEvents"
                    ]
                ),
                ("Resource", "*")
              ]
          )
        ]
        "MyLambdaExecutionPolicy"

spec :: Spec
spec =
  describe "LambdaGoldenTests" $ do
    it "Lambda Template" $ do
      runGoldenTest "simple-lambda" (Stratosphere.encodeTemplate template)
