data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "quality_gate_lambda" {
  name               = "nyc-taxi-quality-gate-lambda-role-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role" "master_data_frehness_lambda" {
  name               = "nyc-taxi-master-data-frehness-lambda-role-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role" "redshift_runner_lambda" {
  name               = "nyc-taxi-redshift-runner-lambda-role-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "quality_gate_basic_execution" {
  role       = aws_iam_role.quality_gate_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "master_data_frehness_basic_execution" {
  role       = aws_iam_role.master_data_frehness_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "redshift_runner_basic_execution" {
  role       = aws_iam_role.redshift_runner_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "quality_gate_data_access" {
  name = "nyc-taxi-quality-gate-data-access"
  role = aws_iam_role.quality_gate_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadJobASummaries"
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.datalake.arn}/${var.project_prefix}/audit/run_summaries/*/jobA_summary.json"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "master_data_frehness_data_access" {
  name = "nyc-taxi-master-data-frehness-data-access"
  role = aws_iam_role.master_data_frehness_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadJobBSummaries"
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.datalake.arn}/${var.project_prefix}/audit/run_summaries/*/jobB_summary.json"
        ]
      },
      {
        Sid      = "PublishNotifications"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "redshift_runner_data_api_access" {
  name = "nyc-taxi-redshift-runner-data-api-access"
  role = aws_iam_role.redshift_runner_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RedshiftDataApiExecute"
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult"
        ]
        Resource = "*"
      },
      {
        Sid    = "ReadRedshiftSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:*"
      },
      {
        Sid    = "DecryptSecretKeyIfCustomerManaged"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
      }
    ]
  })
}
