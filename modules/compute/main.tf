# Fetch the latest Amazon Linux 23 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# User data script to configure WordPress
locals {
  user_data = base64encode(<<-EOT
              #!/bin/bash
              dnf update -y
              dnf install -y httpd php php-mysqlnd wget tar -y
              systemctl start httpd
              systemctl enable httpd
              
              # Download and configure WordPress
              cd /var/www/html
              wget https://wordpress.org/latest.tar.gz
              tar -xzf latest.tar.gz
              cp -r wordpress/* .
              rm -rf wordpress latest.tar.gz
              
              # Setup WordPress config
              cp wp-config-sample.php wp-config.php
              sed -i 's/database_name_here/${var.db_name}/g' wp-config.php
              sed -i 's/username_here/${var.db_user}/g' wp-config.php
              sed -i 's/password_here/${var.db_password}/g' wp-config.php
              sed -i 's/localhost/${var.db_endpoint}/g' wp-config.php
              
              # Fix permissions
              chown -R apache:apache /var/www/html
              chmod -R 755 /var/www/html
              EOT
  )
}

resource "aws_launch_template" "wordpress" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ec2_sg_id]
  }

  user_data = local.user_data

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-wordpress-server" }
  }
}

resource "aws_autoscaling_group" "wordpress" {
  name_prefix         = "${var.name}-asg-"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 4
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-wordpress-server"
    propagate_at_launch = true
  }
}

# --- Scaling Policies & Alarms ---

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.wordpress.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 30
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.wordpress.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.name}-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 30
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 40

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}