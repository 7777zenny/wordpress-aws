data "aws_availability_zones" "available" {
  state = "available"
}

module "network" {
  source = "./modules/network"

  name     = var.project_name
  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "security" {
  source = "./modules/security"

  name   = var.project_name
  vpc_id = module.network.vpc_id
}

module "database" {
  source = "./modules/database"

  name          = var.project_name
  vpc_id        = module.network.vpc_id
  db_subnet_ids = module.network.private_db_subnet_ids
  rds_sg_id     = module.security.rds_sg_id
  db_password   = var.db_password
}

module "alb" {
  source = "./modules/alb"

  name              = var.project_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
}

module "compute" {
  source = "./modules/compute"

  name                  = var.project_name
  vpc_id                = module.network.vpc_id
  subnet_ids            = module.network.private_app_subnet_ids
  ec2_sg_id             = module.security.ec2_sg_id
  db_endpoint           = module.database.endpoint
  db_name               = module.database.database_name
  db_user               = module.database.database_username
  db_password           = var.db_password
  target_group_arn      = module.alb.target_group_arn
  
  # Pass the IAM instance profile name here:
  instance_profile_name = module.iam.instance_profile_name
}
# Commented out due to CloudFront Error: "Your account must be verified before you can add new CloudFront resources"
# module "cloudfront" {
#   source = "./modules/cloudfront"

#   name         = var.project_name
#   alb_dns_name = module.alb.alb_dns_name
# }

module "iam" {
  source = "./modules/iam"
  name   = var.project_name
}

