resource "aws_lb" "wordpress" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.name}-alb" }
}

resource "aws_lb_target_group" "wordpress" {
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 1. HTTP Listener (Port 80) - Automatically redirects all traffic to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
    }
  }
}

# 2. HTTPS Listener (Port 443) - Forwards secure traffic to the WordPress Target Group
# Commented out due to no certificate issue
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.wordpress.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = var.certificate_arn # Requires an ACM Certificate ARN variable

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.wordpress.arn
#   }
# }