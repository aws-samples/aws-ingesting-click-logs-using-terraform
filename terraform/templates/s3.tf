

resource "aws_s3_bucket" "click_logger_firehose_delivery_s3_bucket" {
  bucket = "${var.app_prefix}-${var.stage_name}-firehose-delivery-bucket-${data.aws_caller_identity.current.account_id}"
  region = "${data.aws_region.current.name}"
  acl    = "private"

  tags = {
    Name        = "Firehose S3 Delivery bucket"
    Environment = "${var.stage_name}"
  }
}

output "S3" {
  value = aws_s3_bucket.click_logger_firehose_delivery_s3_bucket
}