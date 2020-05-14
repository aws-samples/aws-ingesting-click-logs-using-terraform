
resource "aws_api_gateway_rest_api" "click_logger_api" {
  name = "${var.app_prefix}-api"
  description = "click logger api"
  
}

#create a resource with name 'resource' in the gateway api , many resources can be created like this
resource "aws_api_gateway_resource" "resource" {
  path_part   = "clicklogger"
  parent_id   = "${aws_api_gateway_rest_api.click_logger_api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.click_logger_api.id}"
  depends_on = ["aws_api_gateway_rest_api.click_logger_api"]
}

resource "aws_api_gateway_account" "click_logger_api_gateway_account" {
  cloudwatch_role_arn = "${aws_iam_role.click_logger_api_gateway_cloudwatch_role.arn}"
}

resource "aws_cloudwatch_log_group" "clicklogger-api-log-group" {
  name              = "/aws/apigateway/${var.app_prefix}-API-Gateway-Execution-Logs/${var.stage_name}"
  retention_in_days = 7
}

resource "aws_api_gateway_method_settings" "general_settings" {
  rest_api_id = "${aws_api_gateway_rest_api.click_logger_api.id}"
  stage_name  = "${aws_api_gateway_deployment.clicklogger_deployment.stage_name}"
  method_path = "*/*"
  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled        = true
    data_trace_enabled     = true
    logging_level          = "INFO"
    # Limit the rate of calls to prevent abuse and unwanted charges
    throttling_rate_limit  = 100
    throttling_burst_limit = 50 
  }
}

resource "aws_api_gateway_authorizer" "clicklogger-authorizer" {
  name                   = "clicklogger-authorizer"
  rest_api_id            = "${aws_api_gateway_rest_api.click_logger_api.id}"
  authorizer_uri         = "${aws_lambda_function.lambda_clicklogger_authorizer.invoke_arn}"
  authorizer_credentials = "${aws_iam_role.click_logger_invocation_role.arn}"
  identity_source        = "method.request.header.Authorization"
  type                   = "TOKEN"
}


resource "aws_api_gateway_request_validator" "clicklogger_validator" {
  name                        = "${var.app_prefix}-validator"
  rest_api_id = "${aws_api_gateway_rest_api.click_logger_api.id}"
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "clicklogger_model" {
  rest_api_id  = "${aws_api_gateway_rest_api.click_logger_api.id}"
  name         = "${var.app_prefix}model"
  description  = "${var.app_prefix}-JSON schema"
  content_type = "application/json"

  schema = <<EOF
  {
      "$schema": "http://json-schema.org/draft-04/schema#",
      "title": "${var.app_prefix}",
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "contextid": {
          "type": "string"
        },
        "requestid": {
          "type": "string"
        },
        "callerid": {
          "type": "string"
        },
        "action": {
          "type": "string"
        },
        "component": {
          "type": "string"
        },
        "type": {
          "type": "string"
        }
        
      },
      "required": ["contextid", "requestid", "callerid", "action", "component","type"]
  }
  EOF
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.click_logger_api.id}"
  resource_id   = "${aws_api_gateway_resource.resource.id}"
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = "${aws_api_gateway_authorizer.clicklogger-authorizer.id}"
  depends_on = ["aws_api_gateway_rest_api.click_logger_api","aws_api_gateway_resource.resource", 
                  "aws_api_gateway_authorizer.clicklogger-authorizer"
                  ,
                   "aws_api_gateway_model.clicklogger_model",
                   "aws_api_gateway_request_validator.clicklogger_validator"
                  ]
  request_models = {
    "application/json" = "${aws_api_gateway_model.clicklogger_model.name}"
  }
  request_validator_id = "${aws_api_gateway_request_validator.clicklogger_validator.id}"
  request_parameters = {
     "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "integration" {
  type                    = "AWS"
  rest_api_id             = "${aws_api_gateway_rest_api.click_logger_api.id}"
  resource_id             = "${aws_api_gateway_resource.resource.id}"
  http_method             = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "POST"
  uri                     = "${aws_lambda_function.lambda_clicklogger.invoke_arn}"
  depends_on = ["aws_api_gateway_rest_api.click_logger_api","aws_api_gateway_resource.resource",
                "aws_api_gateway_method.method"]
  }
  

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.click_logger_api.id}"
  resource_id = "${aws_api_gateway_resource.resource.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }
  response_models = {
         "application/json" = "Empty"
    }
  depends_on = ["aws_api_gateway_resource.resource","aws_api_gateway_rest_api.click_logger_api",
                "aws_api_gateway_method.method"]
}


resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = "${aws_api_gateway_rest_api.click_logger_api.id}"
  resource_id = "${aws_api_gateway_resource.resource.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "${aws_api_gateway_method_response.response_200.status_code}"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With'",
    "method.response.header.Access-Control-Allow-Methods" = "'*'"
  }
   
  depends_on = ["aws_api_gateway_resource.resource","aws_api_gateway_rest_api.click_logger_api",
                 "aws_api_gateway_method_response.response_200","aws_api_gateway_method.method",
                 "aws_api_gateway_integration.integration"]
}

resource "aws_api_gateway_deployment" "clicklogger_deployment" {
  
  rest_api_id = "${aws_api_gateway_rest_api.click_logger_api.id}"
  stage_name  = "${var.stage_name}"

  depends_on = ["aws_api_gateway_integration.integration"]
}

output "deployment-url" {
  value = "${aws_api_gateway_deployment.clicklogger_deployment.invoke_url}"
}