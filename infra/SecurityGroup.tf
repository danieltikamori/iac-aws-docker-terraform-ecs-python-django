# Public Subnet security group (ALB)
resource "aws_security_group" "alb" {
  name        = "alb_ECS"
  description = "Application Load Balancer - Public"
  vpc_id      = module.vpc.vpc_id

  # tags = {
  #   Name = "alb"
  # }
}

resource "aws_security_group_rule" "tcp_alb" {
  type              = "ingress"
  from_port         = 8000 # Ports allowed to access the ALB
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # 0.0.0.0  - 255.255.255.255
  # ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = aws_security_group.alb.id # The ID of the security group to authorize access to.
}
resource "aws_security_group_rule" "tcp_alb" {
  type              = "egress"
  from_port         = 0 # Ports allowed to respond
  to_port           = 0
  protocol          = "-1" # All protocols
  cidr_blocks       = ["0.0.0.0/0"] # 0.0.0.0  - 255.255.255.255
  # ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = aws_security_group.alb.id # The ID of the security group to authorize access to.
}

# Private Subnet security group
resource "aws_security_group" "privatenet" {
  name        = "private_ECS"
  description = "To access the Private subnet"
  vpc_id      = module.vpc.vpc_id

  # tags = {
  #   Name = "alb"
  # }
}
resource "aws_security_group_rule" "ingress_ECS" {
  type              = "ingress"
  from_port         = 0 # Ports allowed to access the Private subnet
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.alb.id # Ingress only from the ALB Security Group
  security_group_id = aws_security_group.privatenet.id # The ID of the security group to authorize access to.
}
resource "aws_security_group_rule" "egress_ECS" {
  type              = "egress"
  from_port         = 0 # Ports allowed to respond
  to_port           = 0
  protocol          = "-1" # All protocols
  source_security_group_id = aws_security_group.alb.id # Egress only to the ALB Security Group
  # ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = aws_security_group.privatenet.id # The ID of the security group to authorize access to.
}