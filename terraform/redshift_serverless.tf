resource "random_password" "redshift_admin_password" {
  length           = 24
  special          = true
  override_special = "!@#%^*()-_=+[]{}"
}

resource "aws_secretsmanager_secret" "redshift_admin" {
  name        = var.redshift_secret_name
  description = "Generated Redshift Serverless admin credentials"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "redshift_admin" {
  secret_id = aws_secretsmanager_secret.redshift_admin.id
  secret_string = jsonencode({
    engine         = "redshift"
    host           = ""
    port           = 5439
    username       = var.redshift_admin_username
    password       = random_password.redshift_admin_password.result
    dbname         = var.redshift_database_name
    workgroup_name = var.redshift_workgroup_name
    namespace_name = var.redshift_namespace_name
  })
}

resource "aws_redshiftserverless_namespace" "pipeline" {
  namespace_name      = var.redshift_namespace_name
  db_name             = var.redshift_database_name
  admin_username      = var.redshift_admin_username
  admin_user_password = random_password.redshift_admin_password.result
  iam_roles           = [aws_iam_role.redshift_serverless_access.arn]
  tags                = var.tags
}

resource "aws_redshiftserverless_workgroup" "pipeline" {
  workgroup_name       = var.redshift_workgroup_name
  namespace_name       = aws_redshiftserverless_namespace.pipeline.namespace_name
  base_capacity        = var.redshift_base_capacity
  publicly_accessible  = var.redshift_publicly_accessible
  subnet_ids           = aws_subnet.public[*].id
  security_group_ids   = [aws_security_group.redshift.id]
  enhanced_vpc_routing = false
  tags                 = var.tags
}
