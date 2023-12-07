#list of functions to deploy
lambda_functions = [
  { name = "main", s3_object = "production/das-functionName-v0.1.9.zip" }
]

cloudwatch_alarms = [
  {
    name                = "AutomaticScalingOutMemoryDB",
    comparison_operator = "GreaterThanOrEqualToThreshold"
    metric_name         = "DatabaseMemoryUsagePercentage",
    namespace           = "AWS/MemoryDB",
    period              = 60,
    evaluation_periods  = 1
    statistic           = "Maximum",
    threshold           = 80
    cluster_name        = "distributed-atom-space",
    s3_object           = "production/documentdb-scale-out.zip"
  },
  {
    name                = "AutomaticScalingInMemoryDB",
    comparison_operator = "LessThanOrEqualToThreshold"
    metric_name         = "DatabaseMemoryUsagePercentage",
    namespace           = "AWS/MemoryDB",
    period              = 60,
    evaluation_periods  = 1
    statistic           = "Maximum",
    threshold           = 50
    cluster_name        = "distributed-atom-space",
    s3_object           = "production/documentdb-scale-in.zip"
  },
]
