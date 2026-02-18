output "aws_region" {
  description = "AWS region where resources are created."
  value       = var.aws_region
}

output "bucket_name" {
  description = "Created S3 data lake bucket."
  value       = aws_s3_bucket.datalake.id
}

output "project_prefix" {
  description = "Top-level prefix for lake layers."
  value       = var.project_prefix
}

output "glue_script_s3_uris" {
  description = "S3 locations of uploaded Glue scripts."
  value = {
    job_a = "s3://${aws_s3_bucket.datalake.id}/${aws_s3_object.glue_scripts["job_a"].key}"
    job_b = "s3://${aws_s3_bucket.datalake.id}/${aws_s3_object.glue_scripts["job_b"].key}"
    job_c = "s3://${aws_s3_bucket.datalake.id}/${aws_s3_object.glue_scripts["job_c"].key}"
  }
}

output "glue_job_names" {
  description = "Names of provisioned Glue jobs."
  value = {
    job_a = aws_glue_job.job_a.name
    job_b = aws_glue_job.job_b.name
    job_c = aws_glue_job.job_c.name
  }
}

output "glue_role_arn" {
  description = "IAM role ARN used by Glue jobs."
  value       = aws_iam_role.glue_execution.arn
}

output "lambda_function_names" {
  description = "Names of provisioned Lambda functions."
  value = {
    quality_gate         = aws_lambda_function.quality_gate.function_name
    master_data_frehness = aws_lambda_function.master_data_frehness.function_name
    redshift_runner      = aws_lambda_function.redshift_runner.function_name
  }
}

output "lambda_function_arns" {
  description = "ARNs of provisioned Lambda functions."
  value = {
    quality_gate         = aws_lambda_function.quality_gate.arn
    master_data_frehness = aws_lambda_function.master_data_frehness.arn
    redshift_runner      = aws_lambda_function.redshift_runner.arn
  }
}

output "step_function_name" {
  description = "Provisioned Step Functions state machine name."
  value       = aws_sfn_state_machine.pipeline.name
}

output "step_function_arn" {
  description = "Provisioned Step Functions state machine ARN."
  value       = aws_sfn_state_machine.pipeline.arn
}

output "redshift_namespace_name" {
  description = "Provisioned Redshift Serverless namespace name."
  value       = aws_redshiftserverless_namespace.pipeline.namespace_name
}

output "redshift_workgroup_name" {
  description = "Provisioned Redshift Serverless workgroup name."
  value       = aws_redshiftserverless_workgroup.pipeline.workgroup_name
}

output "redshift_workgroup_endpoint_address" {
  description = "Redshift Serverless workgroup endpoint address."
  value       = try(aws_redshiftserverless_workgroup.pipeline.endpoint[0].address, null)
}

output "redshift_workgroup_endpoint_port" {
  description = "Redshift Serverless workgroup endpoint port."
  value       = try(aws_redshiftserverless_workgroup.pipeline.endpoint[0].port, null)
}

output "redshift_serverless_role_arn" {
  description = "IAM role attached to Redshift Serverless namespace."
  value       = aws_iam_role.redshift_serverless_access.arn
}

output "redshift_secret_arn" {
  description = "Secrets Manager secret ARN holding generated Redshift credentials."
  value       = aws_secretsmanager_secret.redshift_admin.arn
}

output "sns_pipeline_alerts_topic_arn" {
  description = "SNS topic ARN used for pipeline alerts and Step Functions execution input."
  value       = aws_sns_topic.pipeline_alerts.arn
}

output "eventbridge_s3_raw_yellow_trips_rule_name" {
  description = "EventBridge rule that triggers pipeline on raw yellow trips uploads."
  value       = aws_cloudwatch_event_rule.s3_raw_yellow_trips_created.name
}

output "eventbridge_s3_raw_yellow_trips_rule_arn" {
  description = "EventBridge rule ARN for raw yellow trips upload trigger."
  value       = aws_cloudwatch_event_rule.s3_raw_yellow_trips_created.arn
}
