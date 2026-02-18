resource "aws_glue_crawler" "yellow_trips_enriched" {
  name          = "yellow_trips_enriched"
  role          = aws_iam_role.glue_execution.arn
  database_name = aws_glue_catalog_database.db_curated.name
  tags          = var.tags

  s3_target {
    path = "s3://${aws_s3_bucket.datalake.id}/${var.project_prefix}/curated/yellow_trips_enriched/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}

resource "aws_glue_crawler" "taxi_zone_master" {
  name          = "taxi_zone_master"
  role          = aws_iam_role.glue_execution.arn
  database_name = aws_glue_catalog_database.db_master.name
  tags          = var.tags

  s3_target {
    path = "s3://${aws_s3_bucket.datalake.id}/${var.project_prefix}/master/taxi_zone_master/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}

resource "aws_glue_crawler" "vendor_master" {
  name          = "vendor_master"
  role          = aws_iam_role.glue_execution.arn
  database_name = aws_glue_catalog_database.db_master.name
  tags          = var.tags

  s3_target {
    path = "s3://${aws_s3_bucket.datalake.id}/${var.project_prefix}/master/vendor_master/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}

resource "aws_glue_crawler" "ratecode_master" {
  name          = "ratecode_master"
  role          = aws_iam_role.glue_execution.arn
  database_name = aws_glue_catalog_database.db_master.name
  tags          = var.tags

  s3_target {
    path = "s3://${aws_s3_bucket.datalake.id}/${var.project_prefix}/master/ratecode_master/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}
