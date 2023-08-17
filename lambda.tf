variable "lambda_functions" {
  type = list(object({
    name      = string
    s3_object = string
  }))
}

output "functions_arn" {
  value = aws_lambda_function.functions.*.arn
}

resource "aws_lambda_function" "functions" {
  count         = length(var.lambda_functions)
  function_name = join("-", ["DAS", var.lambda_functions[count.index].name, "lambda_function"])
  role          = aws_iam_role.iam_for_lambda.arn
  runtime       = "python3.10"
  handler       = "lambda-function.lambda_handler"
  s3_bucket     = "das.singularitynet.io"
  s3_key        = var.lambda_functions[count.index].s3_object
  timeout       = 180
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "das_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
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
