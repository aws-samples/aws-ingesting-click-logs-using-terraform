
resource "aws_kinesis_firehose_delivery_stream" "click_logger_firehose_delivery_stream" {
  name = "${var.app_prefix}-firehose-delivery-stream"
  depends_on = ["aws_s3_bucket.click_logger_firehose_delivery_s3_bucket"]
  
  destination = "extended_s3"
  
  extended_s3_configuration {
    role_arn           = "${aws_iam_role.click_logger_stream_consumer_firehose_role.arn}"
    bucket_arn         = "${aws_s3_bucket.click_logger_firehose_delivery_s3_bucket.arn}"
    buffer_size        = 64
    buffer_interval    = 60
    cloudwatch_logging_options {
      enabled = true
      log_group_name = "/aws/kinesis_firehose_delivery_stream/click_logger_firehose_delivery_stream"
      log_stream_name = "click_logger_firehose_delivery_stream"
    }
    compression_format = "UNCOMPRESSED"
    prefix = "clicklog/data=!{timestamp:yyyy}-!{timestamp:MM}-!{timestamp:dd}/"
    error_output_prefix = "clicklog_error/error=!{firehose:error-output-type}data=!{timestamp:yyyy}-!{timestamp:MM}-!{timestamp:dd}/"

    
    data_format_conversion_configuration {
      enabled = true

      input_format_configuration {
        deserializer {
          open_x_json_ser_de {
            case_insensitive = true
          }
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {
            compression = "SNAPPY"
          }
        }
      }

      schema_configuration  {
        database_name = "${aws_glue_catalog_database.aws_glue_click_logger_database.name}"
        role_arn = "${aws_iam_role.click_logger_stream_consumer_firehose_role.arn}"
        table_name = "${aws_glue_catalog_table.aws_glue_click_logger_catalog_table.name}"
        region = "${data.aws_region.current.name}"
      }
    }
  

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_clicklogger_stream_consumer.arn}:$LATEST"
        }
      }
    }
   }
}        