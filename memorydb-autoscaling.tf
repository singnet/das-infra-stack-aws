variable "cloudwatch_alarms" {
  type = map(object({
    name                = string
    comparison_operator = string,
    metric_name         = string,
    namespace           = string,
    period              = number,
    statistic           = string,
    threshold           = number,
    cluster_name        = string,
    s3_object           = string
  }))
}

resource "aws_sns_topic" "memory_db_scaling_topic" {
  for_each = var.cloudwatch_alarms
  name     = "${each.value.name}Topic"
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
  endpoint  = "ARN_LAMBDA"
}

resource "aws_lambda_function" "functions" {
  count         = length(var.cloudwatch_alarms)
  function_name = var.cloudwatch_alarms[count.index].name
  role          = aws_iam_role.iam_for_lambda.arn
  runtime       = "python3.7"
  handler       = "handler.handle"
  s3_bucket     = "das.singularitynet.io"
  s3_key        = var.cloudwatch_alarms[count.index].s3_object
  timeout       = 180
}
