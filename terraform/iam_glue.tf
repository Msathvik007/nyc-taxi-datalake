data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_execution" {
  name               = "nyc-taxi-glue-execution-role-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
  tags               = var.tags
}

locals {
  glue_managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ])
}

resource "aws_iam_role_policy_attachment" "glue_managed_policies" {
  for_each = local.glue_managed_policy_arns

  role       = aws_iam_role.glue_execution.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "glue_data_access" {
  statement {
    sid = "AllowListBucketForProjectPrefix"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.datalake.arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.project_prefix}/*"]
    }
  }

  statement {
    sid = "AllowObjectReadWriteForProjectPrefix"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.datalake.arn}/${var.project_prefix}/*"
    ]
  }

  statement {
    sid = "AllowGlueCloudWatchLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*:log-stream:*"
    ]
  }
}

resource "aws_iam_role_policy" "glue_data_access" {
  name   = "nyc-taxi-glue-data-access"
  role   = aws_iam_role.glue_execution.id
  policy = data.aws_iam_policy_document.glue_data_access.json
}

resource "aws_iam_role_policy" "glue_secrets_manager_service_linked" {
  name = "nyc-taxi-glue-secretsmanager-service-linked"
  role = aws_iam_role.glue_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGlueToManageServiceLinkedSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:TagResource",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutResourcePolicy",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:DeleteResourcePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "glue_secrets_manager_kms" {
  name = "nyc-taxi-glue-secretsmanager-kms"
  role = aws_iam_role.glue_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowSecretsManagerServiceLinkedRole"
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "secretsmanager.amazonaws.com"
          }
        }
      },
      {
        Sid    = "AllowSecretsManagerAccessForGlue"
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:TagResource",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKMSDecryptIfRequired"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}
