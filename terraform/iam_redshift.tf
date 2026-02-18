data "aws_iam_policy_document" "redshift_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "redshift.amazonaws.com",
        "redshift-serverless.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "redshift_serverless_access" {
  name               = "nyc-taxi-redshift-serverless-access-role-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.redshift_assume_role.json
  tags               = var.tags
}

locals {
  redshift_managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/AmazonRedshiftAllCommandsFullAccess"
  ])
}

resource "aws_iam_role_policy_attachment" "redshift_managed_policies" {
  for_each = local.redshift_managed_policy_arns

  role       = aws_iam_role.redshift_serverless_access.name
  policy_arn = each.value
}
