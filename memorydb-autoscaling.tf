variable "cloudwatch_alarms" {
  type = list(object({
    name                = string
    comparison_operator = string,
    metric_name         = string,
    namespace           = string,
    period              = number,
    statistic           = string,
    threshold           = number,
    cluster_name        = string,
    s3_object           = string,
    evaluation_periods  = number,
  }))
}

resource "aws_sns_topic" "memory_db_scaling_topic" {
  count = length(var.cloudwatch_alarms)
  name  = "${var.cloudwatch_alarms[count.index].name}Topic"
}

resource "aws_cloudwatch_metric_alarm" "memory_usage_scaling_out_alarm" {
  count               = length(var.cloudwatch_alarms)
  alarm_name          = "${var.cloudwatch_alarms[count.index].name}Alarm"
  comparison_operator = var.cloudwatch_alarms[count.index].comparison_operator
  evaluation_periods  = var.cloudwatch_alarms[count.index].evaluation_periods
  metric_name         = var.cloudwatch_alarms[count.index].metric_name
  namespace           = var.cloudwatch_alarms[count.index].namespace
  period              = var.cloudwatch_alarms[count.index].period
  statistic           = var.cloudwatch_alarms[count.index].statistic
  threshold           = var.cloudwatch_alarms[count.index].threshold

  dimensions = {
    ClusterName = var.cloudwatch_alarms[count.index].cluster_name
  }

  alarm_actions = [aws_sns_topic.memory_db_scaling_topic[count.index].arn]
}


resource "aws_sns_topic_subscription" "lambda_subscription" {
  count     = length(var.cloudwatch_alarms)
  topic_arn = aws_sns_topic.memory_db_scaling_topic[count.index].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.auto_scaling[count.index].arn
}

resource "aws_iam_role" "iam_for_auto_scaling_lambda" {
  name               = "memorydb_autoscaling_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "auto_scaling_policy" {
  name        = "auto_scaling_policy"
  description = "Policy for CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "logs:CreateLogGroup",
        Resource = "arn:aws:logs:${data.aws_region.current.endpoint}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = aws_lambda_function.auto_scaling.*.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "logs_attachment" {
  role       = aws_iam_role.iam_for_auto_scaling_lambda.name
  policy_arn = aws_iam_policy.auto_scaling_policy.arn
}

resource "aws_lambda_function" "auto_scaling" {
  count         = length(var.cloudwatch_alarms)
  function_name = var.cloudwatch_alarms[count.index].name
  role          = aws_iam_role.iam_for_auto_scaling_lambda.arn
  runtime       = "python3.7"
  handler       = "lambda_function.lambda_handler"
  s3_bucket     = "das.singularitynet.io"
  s3_key        = var.cloudwatch_alarms[count.index].s3_object
  timeout       = 180
}
