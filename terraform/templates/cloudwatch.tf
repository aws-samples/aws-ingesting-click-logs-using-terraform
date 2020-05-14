

resource "aws_cloudwatch_log_group" "lambda_click_logger_log_group" {
  name              = "/aws/lambda/${var.app_prefix}/${aws_lambda_function.lambda_clicklogger.function_name}"
  retention_in_days = 3
  depends_on = ["aws_lambda_function.lambda_clicklogger"]
}

resource "aws_cloudwatch_log_group" "lambda_click_logger_authorizer_log_group" {
  name              = "/aws/lambda/${var.app_prefix}/${aws_lambda_function.lambda_clicklogger_authorizer.function_name}"
  retention_in_days = 3
  depends_on = ["aws_lambda_function.lambda_clicklogger_authorizer"]
}

resource "aws_cloudwatch_log_group" "click_logger_firehose_delivery_stream_log_group" {
  name              = "/aws/kinesis_firehose_delivery_stream/${var.app_prefix}/click_logger_firehose_delivery_stream"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_stream" "click_logger_firehose_delivery_stream" {
  name           = "${var.app_prefix}-firehose-delivery-stream"
  log_group_name = "${aws_cloudwatch_log_group.click_logger_firehose_delivery_stream_log_group.name}"
}
