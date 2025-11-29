resource "aws_rds_cluster" "this" {
  count              = var.use_aurora ? 1 : 0
  cluster_identifier = "aurora-${substr(md5(var.db_name),0,8)}"
  engine             = var.engine
  engine_version     = var.engine_version
  database_name      = var.db_name
  master_username    = var.username
  master_password    = var.password
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  backup_retention_period = var.backup_retention_period
  port = var.port
  skip_final_snapshot = var.skip_final_snapshot

  tags = merge({ Name = "aurora-cluster" }, var.tags)
}

resource "aws_rds_cluster_instance" "writer" {
  count              = var.use_aurora ? 1 : 0
  identifier         = "aurora-writer-${substr(md5(var.db_name),0,8)}"
  cluster_identifier = aws_rds_cluster.this[0].id
  instance_class     = var.instance_class
  engine             = var.engine
  engine_version     = var.engine_version

  publicly_accessible = var.publicly_accessible
  db_subnet_group_name = aws_db_subnet_group.this.name
  tags = merge({ Name = "aurora-writer" }, var.tags)
}
