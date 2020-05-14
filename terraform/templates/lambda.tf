
resource "aws_lambda_function" "lambda_clicklogger" {
  filename      = "${var.lambda_source_zip_path}"
  function_name = "${var.app_prefix}-lambda"
  role          = "${aws_iam_role.click_logger_lambda_role.arn}"
  handler       = "com.clicklogs.Handlers.ClickLoggerHandler::handleRequest"
  runtime       = "java8"
  memory_size   = 2048
  timeout       = 300
  
  source_code_hash = "${filebase64sha256(var.lambda_source_zip_path)}"
  depends_on = ["aws_iam_role.click_logger_lambda_role", "aws_kinesis_firehose_delivery_stream.click_logger_firehose_delivery_stream"]

  environment {
    variables = {
      STREAM_NAME = "${aws_kinesis_firehose_delivery_stream.click_logger_firehose_delivery_stream.name}"
      #REGION = "${data.aws_region.current.name}"
    }
  }
}

resource "aws_lambda_function" "lambda_clicklogger_stream_consumer" {
  filename      = "${var.lambda_source_zip_path}"
  function_name = "${var.app_prefix}-lambda-stream-consumer"
  role          = "${aws_iam_role.click_logger_lambda_role.arn}"
  handler       = "com.clicklogs.Handlers.ClickLoggerStreamHandler::handleRequest"
  runtime       = "java8"
  memory_size   = 2048
  timeout       = 300
  
  source_code_hash = "${filebase64sha256(var.lambda_source_zip_path)}"
  depends_on = ["aws_iam_role.click_logger_lambda_role", "aws_dynamodb_table.click-logger-table"]

  environment {
    variables = {
      DB_TABLE = "${aws_dynamodb_table.click-logger-table.name}"
      #REGION = "${data.aws_region.current.name}"
    }
  }
}

resource "aws_lambda_function" "lambda_clicklogger_authorizer" {
  filename      = "${var.lambda_source_zip_path}"
  function_name = "${var.app_prefix}-lambda-authorizer"
  role          = "${aws_iam_role.click_logger_lambda_role.arn}"
  handler       = "com.clicklogs.Handlers.APIGatewayAuthorizerHandler::handleRequest"
  runtime       = "java8"
  memory_size   = 2048
  timeout       = 300
  
  source_code_hash = "${filebase64sha256(var.lambda_source_zip_path)}"
  depends_on = ["aws_iam_role.click_logger_lambda_role"]

  environment {
    variables = {
      AUTH_TOKENS = "ALLOW=ORDERAPP;ALLOW=BILLAPP;"
    }
  }
}


output "lambda-clicklogger" {
  value = "${aws_lambda_function.lambda_clicklogger}"
}

output "lambda-clicklogger-authorzer" {
  value = "${aws_lambda_function.lambda_clicklogger_authorizer}"
}
