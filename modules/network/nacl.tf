# Private App Subnet Network ACL
resource "aws_network_acl" "private_app" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.private_app[*].id

  # Allow inbound ephemeral ports for return traffic from NAT / updates
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow inbound HTTP from the Public Subnets (where the ALB lives)
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.0.0/16" # Adjust to match your VPC CIDR block
    from_port  = 80
    to_port    = 80
  }

  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = { Name = "${var.name}-private-app-nacl" }
}