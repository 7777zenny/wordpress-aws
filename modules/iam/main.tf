resource "aws_iam_role" "ec2_wordpress" {
  name = "${var.name}-ec2-wordpress-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = { Name = "${var.name}-ec2-role" }
}

# Attach AWS managed policy for CloudWatch/Systems Manager (least privilege operational tools)
resource "aws_iam_role_policy_attachment" "ssm_server" {
  role       = aws_iam_role.ec2_wordpress.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile to pass the role to the Auto Scaling Launch Template
resource "aws_iam_instance_profile" "wordpress" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.ec2_wordpress.name
}