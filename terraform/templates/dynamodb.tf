# contextid, callerid, type (page/app), component (page_header/login_popup), action (click/collapse) createdtime
resource "aws_dynamodb_table" "click-logger-table" {
  name              = "${var.app_prefix}table"
  billing_mode      = "PROVISIONED"
  read_capacity     = 5
  write_capacity    = 5
  hash_key          = "requestid"
  range_key         = "contextid"
  
  attribute {
    name = "requestid"
    type = "S"
  }

  attribute {
    name = "contextid"
    type = "S"
  }

  attribute {
    name = "callerid"
    type = "S"
  }

  global_secondary_index {
    name               = "ContextCallerIndex"
    hash_key           = "contextid"
    range_key          = "callerid"
    write_capacity     = 5
    read_capacity      = 5
    projection_type    = "INCLUDE"
    non_key_attributes = ["requestid", "action", "clientip", "component", "createdtime", "type"]
  }

  tags = {
    Name        = "${var.app_prefix}table"
    Environment = "${var.stage_name}"
  }
}