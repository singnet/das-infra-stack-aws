variable "lambda_functions" {
  type = list(object({
    name      = string
    s3_object = string
  }))
}

output "functions_arn" {
  value = aws_lambda_function.functions.*.arn
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "das_lambda" {
  name        = "das_lambda"
  description = "DAS lambda function"

  ingress {}

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lambda_function" "functions" {
  count         = length(var.lambda_functions)
  function_name = join("-", ["das", var.lambda_functions[count.index].name])
  role          = aws_iam_role.iam_for_lambda.arn
  runtime       = "python3.11"
  handler       = "handler.handle"
  s3_bucket     = "das.singularitynet.io"
  s3_key        = var.lambda_functions[count.index].s3_object
  timeout       = 180

  vpc_config {
    subnet_ids         = data.aws_availability_zones.available.zone_ids
    security_group_ids = [aws_security_group.das_lambda.id]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name                = "das_lambda_role"
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [aws_iam_policy.lambda_policy]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name = "das_lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "lambda:InvokeFunction",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:us-east-1:038760728819:*"
      },
      {
        "Effect" : "Allow",
        "Resource" : "*",
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:CreateNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "autoscaling:CompleteLifecycleAction",
          "ec2:DeleteNetworkInterface"
        ]
      }
    ]
  })
}
