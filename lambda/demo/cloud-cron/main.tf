provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}

variable "deploy_bucket_name" {
  default = "sl-brs-cloud-study"
}

variable "deploy_key" {
  default = "WriteToS3Lambda.zip"
}

variable "write_bucket_name" {
  default = "sl-brs-cloud-study"
}

variable "lambda_name" {
  default = "WriteToS3Lambda"
}

variable "lambda_runtime" {
  default = "python3.6"
}

variable "handler_path" {
  default = "WriteToS3.handler"
}

variable "event_name" {
  default = "TriggerEveryMinuteEvent"
}

data "aws_s3_bucket" "cloud_study" {
  bucket = "${var.deploy_bucket_name}"
}

resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  name        = "${var.event_name}"
  description = "${var.event_name}"

  schedule_expression = "cron(* * * * ? *)"

  //schedule_expression = "rate(1 minutes)"
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_target" {
  target_id = "${var.lambda_name}${var.event_name}Target"
  rule      = "${aws_cloudwatch_event_rule.cloudwatch_event_rule.name}"
  arn       = "${aws_lambda_function.lambda.arn}"

  input = <<EOF
{
  "bucket": "${var.deploy_bucket_name}"
}
EOF
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_name}Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_role_policy" {
  name = "${var.lambda_name}RolePolicy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::${var.write_bucket_name}/*"
      ]
    }
  ]
}
  EOF

  role = "${aws_iam_role.lambda_role.id}"
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "lambda_invoke_permission" {
  statement_id  = "${var.lambda_name}${var.event_name}InvokePermission"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.cloudwatch_event_rule.arn}"
}

resource "aws_lambda_function" "lambda" {
  s3_bucket     = "${var.deploy_bucket_name}"
  s3_key        = "${var.deploy_key}"
  function_name = "${var.lambda_name}"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "${var.handler_path}"
  runtime       = "${var.lambda_runtime}"
  timeout       = 10
}
