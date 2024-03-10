resource "aws_lb" "alb" {
  name               = "ECS-Django" # Must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen. If not specified, Terraform will autogenerate a name beginning with tf-lb.
  # internal           = false # optional
  load_balancer_type = "application" # type of load balancer - application or network
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  # enable_deletion_protection = true # If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. It may be troublesome to turn this on for production workloads as it will be difficult to change or switch the Load Balancer.

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  # tags = {
  #   Environment = "production"
  # }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "8000"
  protocol          = "HTTP"
  # ssl_policy        = "ELBSecurityPolicy-2016-08" # If HTTP protocol, no need for SSL and certificate
  # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target.arn
  }
}

resource "aws_lb_target_group" "alb_target" { # Use the IP target group
  name        = "ECS-Django"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
}

# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
# }

output "DNS" {
  value = aws_lb.alb.dns_name # Outputs dns address to make easier to get the Load Balancer DNS. Go to the Main.tf in the environments and use this variable.
}