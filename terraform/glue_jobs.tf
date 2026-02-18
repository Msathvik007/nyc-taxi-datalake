locals {
  common_default_arguments = {
    "--BUCKET"                           = aws_s3_bucket.datalake.id
    "--TempDir"                          = "s3://${aws_s3_bucket.datalake.id}/${var.project_prefix}/glue-tmp/"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
    "--job-language"                     = "python"
    "--enable-glue-datacatalog"          = "true"
  }
}

resource "aws_glue_job" "job_a" {
  name              = "job-a-raw-to-validated"
  role_arn          = aws_iam_role.glue_execution.arn
  glue_version      = var.glue_version
  worker_type       = var.glue_worker_type
  number_of_workers = var.glue_number_of_workers
  max_retries       = 0
  timeout           = 60
  tags              = var.tags

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.datalake.id}/${aws_s3_object.glue_scripts["job_a"].key}"
    python_version  = "3"
  }

  default_arguments = merge(
    local.common_default_arguments,
    {
      "--PROJECT_PREFIX" = var.project_prefix
    }
  )
}

resource "aws_glue_job" "job_b" {
  name              = "job-b-validated-to-master"
  role_arn          = aws_iam_role.glue_execution.arn
  glue_version      = var.glue_version
  worker_type       = var.glue_worker_type
  number_of_workers = var.glue_number_of_workers
  max_retries       = 0
  timeout           = 60
  tags              = var.tags

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.datalake.id}/${aws_s3_object.glue_scripts["job_b"].key}"
    python_version  = "3"
  }

  default_arguments = merge(
    local.common_default_arguments,
    {
      "--additional-python-modules" = "fuzzywuzzy==0.18.0,python-Levenshtein==0.25.1"
    }
  )
}

resource "aws_glue_job" "job_c" {
  name              = "job-c-validated-to-curated"
  role_arn          = aws_iam_role.glue_execution.arn
  glue_version      = var.glue_version
  worker_type       = var.glue_worker_type
  number_of_workers = var.glue_number_of_workers
  max_retries       = 0
  timeout           = 60
  tags              = var.tags

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.datalake.id}/${aws_s3_object.glue_scripts["job_c"].key}"
    python_version  = "3"
  }

  default_arguments = local.common_default_arguments
}
