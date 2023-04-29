provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source      = "terraform-aws-modules/vpc/aws"
  name        = "${var.project_prefix}-vpc"
  cidr        = "10.0.0.0/16"

  azs         = ["ap-southeast-2a", "ap-southeast-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  database_subnets    = ["10.0.21.0/24", "10.0.22.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    User = var.aws_user_tag
    Creator = "terraform"
  }
}

module "cluster" {
  source  = "terraform-aws-modules/rds-aurora/aws"

  name           = "${var.project_prefix}-aurora-db-mysql"
  engine         = "aurora-mysql"
  engine_version = "8.0"
  instance_class = "db.r5.large"
  master_username = "admin"
  master_password = "FWGG&%Ghs26"
  manage_master_user_password = false
  publicly_accessible = true

  create_db_cluster_parameter_group      = true
  db_cluster_parameter_group_name        = "${var.project_prefix}-mysql-parameters"
  db_cluster_parameter_group_family      = "aurora-mysql8.0"
  db_cluster_parameter_group_description = "Mysql parameters example cluster parameter group"
  db_cluster_parameter_group_parameters = [
    {
      name = "binlog_format",
      value = "ROW"
      apply_method = "pending-reboot"
    }
  ]

  instances = {
    one = {}
  }

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name
  
  vpc_security_group_ids = [
    aws_security_group.aurora_mysql_sg.id
  ]

  storage_encrypted   = true
  apply_immediately   = true
  monitoring_interval = 10
  skip_final_snapshot = true

  tags = {
    User = var.aws_user_tag
    Creator   = "terraform"
  }
}

resource "aws_security_group" "aurora_mysql_sg" {
  name_prefix = var.project_prefix
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    User = var.aws_user_tag
    Creator   = "terraform"
  }
}
