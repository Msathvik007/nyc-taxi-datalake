variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the Terraform-managed VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "bucket_name_prefix" {
  description = "Prefix used to build a globally unique S3 bucket name."
  type        = string
  default     = "nyc-taxi-datalake"
}

variable "project_prefix" {
  description = "Top-level S3 prefix for data lake structure."
  type        = string
  default     = "project_step__function"
}

variable "glue_version" {
  description = "Glue version used by all jobs."
  type        = string
  default     = "5.0"
}

variable "glue_worker_type" {
  description = "Worker type used by all jobs."
  type        = string
  default     = "G.1X"
}

variable "glue_number_of_workers" {
  description = "Number of workers used by all jobs."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "nyc-taxi"
    ManagedBy = "terraform"
  }
}

variable "lambda_runtime" {
  description = "Runtime used by Python Lambda functions."
  type        = string
  default     = "python3.12"
}

variable "quality_gate_lambda_name" {
  description = "Lambda name for data quality gate."
  type        = string
  default     = "quality_gate_validated"
}

variable "master_data_frehness_lambda_name" {
  description = "Lambda name for master data freshness check."
  type        = string
  default     = "master_data_frehness"
}

variable "redshift_runner_lambda_name" {
  description = "Lambda name for Redshift SQL runner."
  type        = string
  default     = "redshift_runner"
}

variable "redshift_workgroup_name" {
  description = "Redshift Serverless workgroup name."
  type        = string
  default     = "nyc-taxi-workgroup"
}

variable "redshift_database_name" {
  description = "Redshift Serverless database name."
  type        = string
  default     = "dev"
}

variable "redshift_namespace_name" {
  description = "Redshift Serverless namespace name."
  type        = string
  default     = "nyc-taxi-namespace"
}

variable "redshift_admin_username" {
  description = "Admin username for Redshift namespace."
  type        = string
  default     = "admin"
}

variable "redshift_base_capacity" {
  description = "Base capacity (RPUs) for Redshift Serverless workgroup."
  type        = number
  default     = 8
}

variable "redshift_publicly_accessible" {
  description = "Whether Redshift Serverless workgroup is publicly accessible."
  type        = bool
  default     = true
}

variable "redshift_secret_name" {
  description = "Secrets Manager secret name for generated Redshift admin credentials."
  type        = string
  default     = "redshift-nyc-taxi-admin"
}

variable "redshift_iam_role_arn" {
  description = "Deprecated override. Leave empty; Terraform-managed Redshift IAM role is used."
  type        = string
  default     = ""
}

variable "step_function_name" {
  description = "State machine name for the pipeline orchestration."
  type        = string
  default     = "nyc-taxi-pipeline"
}
