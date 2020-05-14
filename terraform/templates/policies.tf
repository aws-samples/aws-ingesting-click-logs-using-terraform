
resource "aws_iam_policy" "click_loggerlambda_logging_policy" {
  name = "${var.app_prefix}-lambda-logging-policy"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
     {
      "Action": [
        "dynamodb:ListTables",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:PutItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ],
      "Resource": "${aws_dynamodb_table.click-logger-table.arn}",
      "Effect": "Allow"
    },
    {
      "Action": [
        "firehose:*"
      ],
      "Resource": "${aws_kinesis_firehose_delivery_stream.click_logger_firehose_delivery_stream.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "click_logger_invocation_policy" {
  name = "${var.app_prefix}-invocation-policy"
  role = "${aws_iam_role.click_logger_invocation_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.lambda_clicklogger_authorizer.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.click_logger_lambda_role.name}"
  policy_arn = "${aws_iam_policy.click_loggerlambda_logging_policy.arn}"
}


resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_clicklogger.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.click_logger_api.execution_arn}/*/*/*"
  depends_on = ["aws_lambda_function.lambda_clicklogger","aws_api_gateway_rest_api.click_logger_api"]
}


resource "aws_iam_role_policy" "click_logger_api_gateway_cloudwatch_policy" {
  name = "${var.app_prefix}-api-gateway-cloudwatch-policy"
  role = "${aws_iam_role.click_logger_api_gateway_cloudwatch_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}