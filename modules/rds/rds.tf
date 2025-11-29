resource "aws_db_instance" "this" {
  count                     = var.use_aurora ? 0 : 1
  identifier                = "rds-${substr(md5(var.db_name),0,8)}"
  allocated_storage         = var.allocated_storage
  engine                    = var.engine
  engine_version            = var.engine_version
  instance_class            = var.instance_class
  name                      = var.db_name
  username                  = var.username
  password                  = var.password
  port                      = var.port
  multi_az                  = var.multi_az
  storage_type              = var.storage_type
  publicly_accessible       = var.publicly_accessible
  db_subnet_group_name      = aws_db_subnet_group.this.name
  vpc_security_group_ids    = [aws_security_group.db_sg.id]
  parameter_group_name      = var.use_custom_parameter_group ? aws_db_parameter_group.instance_pg[0].name : null
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier

  tags = merge({ Name = "rds-instance" }, var.tags)

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}
