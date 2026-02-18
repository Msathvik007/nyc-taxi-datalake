resource "random_id" "bucket_suffix" {
  byte_length = 3
}

locals {
  bucket_name = "${var.bucket_name_prefix}-${random_id.bucket_suffix.hex}"

  lake_prefixes = toset([
    "${var.project_prefix}/raw/",
    "${var.project_prefix}/raw/yellow_trips/",
    "${var.project_prefix}/raw/taxi_zone_lookup/",
    "${var.project_prefix}/validated/",
    "${var.project_prefix}/curated/",
    "${var.project_prefix}/master/",
    "${var.project_prefix}/audit/",
    "${var.project_prefix}/glue-scripts/",
    "${var.project_prefix}/glue-tmp/"
  ])

  glue_script_sources = {
    job_a = "${path.module}/../glue/Job A/script.py"
    job_b = "${path.module}/../glue/Job B/script.py"
    job_c = "${path.module}/../glue/JobC/script.py"
  }
}

resource "aws_s3_bucket" "datalake" {
  bucket = local.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_ownership_controls" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  rule {
    id     = "expire-audit-objects-after-30-days"
    status = "Enabled"

    filter {
      prefix = "${var.project_prefix}/audit/"
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_object" "lake_folders" {
  for_each = local.lake_prefixes

  bucket  = aws_s3_bucket.datalake.id
  key     = each.value
  content = ""
}

resource "aws_s3_object" "glue_scripts" {
  for_each = local.glue_script_sources

  bucket = aws_s3_bucket.datalake.id
  key    = "${var.project_prefix}/glue-scripts/${each.key}.py"
  source = each.value
  etag   = filemd5(each.value)
}
