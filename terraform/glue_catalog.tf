resource "aws_glue_catalog_database" "db_curated" {
  name = "db_curated"
}

resource "aws_glue_catalog_database" "db_master" {
  name = "db_master"
}
