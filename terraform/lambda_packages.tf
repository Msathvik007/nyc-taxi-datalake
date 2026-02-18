locals {
  lambda_build_dir = "${path.module}/.lambda-builds"
}

data "archive_file" "quality_gate_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/quality_gate"
  output_path = "${local.lambda_build_dir}/quality_gate.zip"
}

data "archive_file" "master_data_frehness_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/master_data_frehness"
  output_path = "${local.lambda_build_dir}/master_data_frehness.zip"
}

data "archive_file" "redshift_runner_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/redshift-runner"
  output_path = "${local.lambda_build_dir}/redshift_runner.zip"
}
