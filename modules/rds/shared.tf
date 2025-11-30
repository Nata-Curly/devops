##############################################
# Shared resources: subnet group, security group
##############################################

resource "aws_db_subnet_group" "this" {
  name       = replace("rds-subnet-group-${substr(md5(join("", var.subnet_ids)), 0, 8)}", "_", "-")
  subnet_ids = var.subnet_ids
  tags       = merge({ Name = "rds-subnet-group" }, var.tags)
}

# Security group allowing access from VPC CIDR (or open to VPC) - adjust as needed
resource "aws_security_group" "db_sg" {
  name        = "rds-sg-${substr(md5(var.vpc_id),0,8)}"
  description = "Security group for RDS created by module"
  vpc_id      = var.vpc_id
  # ingress rules are created as separate resources below depending on inputs
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "rds-sg" }, var.tags)
}

# If allowed_security_group_ids provided, create rules allowing those security groups
resource "aws_security_group_rule" "from_sgs" {
  count                  = length(var.allowed_security_group_ids) > 0 ? length(var.allowed_security_group_ids) : 0
  type                   = "ingress"
  from_port              = var.port
  to_port                = var.port
  protocol               = "tcp"
  security_group_id      = aws_security_group.db_sg.id
  source_security_group_id = var.allowed_security_group_ids[count.index]
}

# If no allowed_security_group_ids provided, fall back to CIDR-based rule
resource "aws_security_group_rule" "from_cidr" {
  count              = length(var.allowed_security_group_ids) == 0 ? 1 : 0
  type               = "ingress"
  from_port          = var.port
  to_port            = var.port
  protocol           = "tcp"
  security_group_id  = aws_security_group.db_sg.id
  cidr_blocks        = length(var.vpc_cidr_block) > 0 ? [var.vpc_cidr_block] : ["10.0.0.0/8"]
}

# Parameter group for single RDS instance (non-Aurora)
resource "aws_db_parameter_group" "instance_pg" {
  count = var.use_aurora ? 0 : 1
  name  = "rds-pg-${substr(md5(var.db_name),0,8)}"
  family = (lower(var.engine) == "postgres" || lower(var.engine) == "postgresql") ? var.parameter_group_family_postgres : var.parameter_group_family_mysql
  description = "DB parameter group for single instance"

  parameter {
    name  = "max_connections"
    value = "200"
  }
  # engine-specific logging param
  parameter {
    name  = (lower(var.engine) == "postgres" || lower(var.engine) == "postgresql") ? "log_statement" : "general_log"
    value = (lower(var.engine) == "postgres" || lower(var.engine) == "postgresql") ? "none" : "0"
  }
  parameter {
    name  = (lower(var.engine) == "postgres" || lower(var.engine) == "postgresql") ? "work_mem" : "max_heap_table_size"
    value = (lower(var.engine) == "postgres" || lower(var.engine) == "postgresql") ? "4MB" : "16M"
  }

  dynamic "parameter" {
    for_each = var.parameters_map
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = var.tags
}

# Parameter group for Aurora cluster
resource "aws_rds_cluster_parameter_group" "cluster_pg" {
  count = var.use_aurora ? 1 : 0
  name  = "aurora-pg-${substr(md5(var.db_name),0,8)}"
  family = var.engine == "aurora-postgresql" ? "aurora-postgresql10" : (var.engine == "aurora-mysql" ? "aurora-mysql5.7" : "aurora-postgresql10")
  description = "Parameter group for Aurora cluster"

  parameter {
    name  = "max_connections"
    value = "200"
  }
  parameter {
    name  = "log_statement"
    value = "none"
  }
  parameter {
    name  = "work_mem"
    value = "4MB"
  }

  dynamic "parameter" {
    for_each = var.parameters_map
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = var.tags
}
