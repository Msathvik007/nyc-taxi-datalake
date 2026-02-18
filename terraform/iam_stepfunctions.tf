data "aws_iam_policy_document" "step_functions_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "step_functions_execution" {
  name               = "nyc-taxi-stepfunctions-execution-role-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.step_functions_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "step_functions_execution" {
  name = "nyc-taxi-stepfunctions-execution-policy"
  role = aws_iam_role.step_functions_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GlueJobsControl"
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]
        Resource = [
          aws_glue_job.job_a.arn,
          aws_glue_job.job_b.arn,
          aws_glue_job.job_c.arn
        ]
      },
      {
        Sid    = "GlueCrawlerControl"
        Effect = "Allow"
        Action = [
          "glue:StartCrawler",
          "glue:GetCrawler"
        ]
        Resource = [
          aws_glue_crawler.yellow_trips_enriched.arn,
          aws_glue_crawler.taxi_zone_master.arn,
          aws_glue_crawler.vendor_master.arn,
          aws_glue_crawler.ratecode_master.arn
        ]
      },
      {
        Sid    = "InvokePipelineLambdas"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.quality_gate.arn,
          aws_lambda_function.master_data_frehness.arn,
          aws_lambda_function.redshift_runner.arn
        ]
      }
    ]
  })
}
