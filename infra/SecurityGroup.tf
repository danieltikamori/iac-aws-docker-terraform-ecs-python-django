# Public Subnet security group (ALB)
resource "aws_security_group" "alb" {
  name        = "alb_ECS"
  description = "Application Load Balancer - Public"
  vpc_id      = module.vpc.vpc_id

  # tags = {
  #   Name = "alb"
  # }
}

resource "aws_security_group_rule" "ingress_alb" {
  type              = "ingress"
  from_port         = 8000 # Ports allowed to access the ALB
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # 0.0.0.0  - 255.255.255.255
  # ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = aws_security_group.alb.id # The ID of the security group to authorize access to.
}
resource "aws_security_group_rule" "egress_alb" {
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


# Private VPC endpoint security group
resource "aws_security_group" "vpc_endpoint_service" {
  name        = "private_VPC_endpoint"
  description = "To access the Private subnet"
  vpc_id      = module.vpc.vpc_id

  # tags = {
  #   Name = "alb"
  # }
}


# resource "aws_security_group" "interface_endpoints" {
#   name        = "${var.environment}-interface-endpoints-sg"
#   description = "Default security group for VPC Interace endpoints"
#   vpc_id      = module.vpc.vpc_id
#   depends_on  = [module.vpc.aws_vpc]
#   ingress {
#     from_port = "0"
#     to_port   = "0"
#     protocol  = "-1"
#     self      = true
#   }

#   egress {
#     from_port = "0"
#     to_port   = "0"
#     protocol  = "-1"
#     self      = true
#   }
# }

# Allow traffic to and from the ECR endpoint

resource "aws_security_group_rule" "ingress_ECR" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  # self = true
  security_group_id = aws_security_group.vpc_endpoint_service.id
  source_security_group_id = aws_security_group.alb.id
  # cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  # cidr_blocks = ["0.0.0.0/0"]
  # # prefix_list_ids = [data.aws_prefix_list.ecr_api_endpoint.id, data.aws_prefix_list.ecr_dkr_endpoint.id]
  # security_group_id = aws_security_group.vpc_endpoint_service.id
}

resource "aws_security_group_rule" "egress_ECR" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  # self = true # not necessary if cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpc_endpoint_service.id
  prefix_list_ids   = [data.aws_prefix_list.ecr_dkr.id, data.aws_prefix_list.s3.id]
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.vpc_endpoint_service.id
}

