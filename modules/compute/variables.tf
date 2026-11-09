variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "ec2_sg_id" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "target_group_arn" {
  type = string
}

variable "instance_profile_name" {
  type = string
}
