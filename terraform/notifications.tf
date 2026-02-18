resource "aws_sns_topic" "pipeline_alerts" {
  name = "nyc-taxi-pipeline-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "pipeline_alerts_email" {
  topic_arn = aws_sns_topic.pipeline_alerts.arn
  protocol  = "email"
  endpoint  = "muskusathvik@gmail.com"
}

data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eventbridge_start_sfn" {
  name               = "nyc-taxi-eventbridge-start-sfn-role-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "eventbridge_start_sfn" {
  name = "nyc-taxi-eventbridge-start-sfn-policy"
  role = aws_iam_role.eventbridge_start_sfn.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowStartPipelineStateMachine"
        Effect = "Allow"
        Action = ["states:StartExecution"]
        Resource = [
          aws_sfn_state_machine.pipeline.arn
        ]
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "s3_raw_yellow_trips_created" {
  name        = "nyc-taxi-s3-raw-yellow-trips-created"
  description = "Trigger Step Functions when objects are uploaded to raw/yellow_trips prefix"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.datalake.id]
      }
      object = {
        key = [
          {
            prefix = "${var.project_prefix}/raw/yellow_trips/"
          }
        ]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "s3_raw_yellow_trips_to_sfn" {
  rule     = aws_cloudwatch_event_rule.s3_raw_yellow_trips_created.name
  arn      = aws_sfn_state_machine.pipeline.arn
  role_arn = aws_iam_role.eventbridge_start_sfn.arn

  input_transformer {
    input_paths = {
      bucket    = "$.detail.bucket.name"
      eventId   = "$.id"
      objectKey = "$.detail.object.key"
      eventTime = "$.time"
    }
    input_template = <<-EOT
{
  "BUCKET": <bucket>,
  "run_id": <eventId>,
  "sns_topic_arn": "${aws_sns_topic.pipeline_alerts.arn}",
  "object_key": <objectKey>,
  "event_time": <eventTime>
}
EOT
  }
}
