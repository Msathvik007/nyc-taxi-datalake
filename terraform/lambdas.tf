resource "aws_lambda_function" "quality_gate" {
  function_name    = var.quality_gate_lambda_name
  role             = aws_iam_role.quality_gate_lambda.arn
  handler          = "app.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 30
  memory_size      = 256
  filename         = data.archive_file.quality_gate_zip.output_path
  source_code_hash = data.archive_file.quality_gate_zip.output_base64sha256
  tags             = var.tags

  environment {
    variables = {
      PROJECT_PREFIX    = var.project_prefix
      DEFAULT_THRESHOLD = "0.7"
    }
  }
}

resource "aws_lambda_function" "master_data_frehness" {
  function_name    = var.master_data_frehness_lambda_name
  role             = aws_iam_role.master_data_frehness_lambda.arn
  handler          = "spp.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 60
  memory_size      = 256
  filename         = data.archive_file.master_data_frehness_zip.output_path
  source_code_hash = data.archive_file.master_data_frehness_zip.output_base64sha256
  tags             = var.tags

  environment {
    variables = {
      PROJECT_PREFIX = var.project_prefix
    }
  }
}

resource "aws_lambda_function" "redshift_runner" {
  function_name    = var.redshift_runner_lambda_name
  role             = aws_iam_role.redshift_runner_lambda.arn
  handler          = "app.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 120
  memory_size      = 512
  filename         = data.archive_file.redshift_runner_zip.output_path
  source_code_hash = data.archive_file.redshift_runner_zip.output_base64sha256
  tags             = var.tags

  environment {
    variables = {
      WORKGROUP_NAME        = aws_redshiftserverless_workgroup.pipeline.workgroup_name
      DATABASE_NAME         = var.redshift_database_name
      SECRET_ARN            = aws_secretsmanager_secret.redshift_admin.arn
      REDSHIFT_IAM_ROLE_ARN = aws_iam_role.redshift_serverless_access.arn
      SQL_FILE_PATH         = "sql/build.sql"
      PROJECT_PREFIX        = var.project_prefix
    }
  }
}
