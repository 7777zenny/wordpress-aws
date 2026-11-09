resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = { Name = "${var.name}-db-subnet-group" }
}

resource "aws_db_instance" "wordpress" {
  identifier             = "${var.name}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 100
  db_name                = "wordpress"
  username               = "admin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = true

  tags = { Name = "${var.name}-wordpress-db" }
}