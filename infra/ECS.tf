module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = var.environment

  cluster_settings = [
  {
    "name": "containerInsights",
    "value": "enabled"
  }
]

  # cluster_configuration = {
  #   execute_command_configuration = {
  #     logging = "OVERRIDE"
  #     log_configuration = {
  #       cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
  #     }
  #   }
  # }

# The block above controls how the "Execute Command" feature works within your ECS cluster.

# Here's a breakdown of what each part does:

# cluster_configuration = { ... }: This block defines various settings for your ECS cluster.

# execute_command_configuration = { ... }: This nested block specifically defines options for the "Execute Command" feature, which allows you to remotely run commands on ECS containers.

# logging = "OVERRIDE": This setting tells ECS to override the default logging behavior for "Execute Command" actions. By default, logs are not collected for these actions.

# log_configuration = { ... }: This nested block defines where the logs for "Execute Command" actions will be sent.

# cloud_watch_log_group_name = "/aws/ecs/aws-ec2": This setting specifies that logs will be sent to a CloudWatch Log Group named "/aws/ecs/aws-ec2". This is the default log group used by ECS for "Execute Command" actions if you don't override it.

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
    # FARGATE_SPOT = {
    #   default_capacity_provider_strategy = {
    #     weight = 50
    #   }
    # }
  }

  # services = {
  #   ecsdemo-frontend = {
  #     cpu    = 1024
  #     memory = 4096

  #     # Container definition(s)
  #     container_definitions = {

  #       fluent-bit = {
  #         cpu       = 512
  #         memory    = 1024
  #         essential = true
  #         image     = "906394416424.dkr.ecr.us-west-2.amazonaws.com/aws-for-fluent-bit:stable"
  #         firelens_configuration = {
  #           type = "fluentbit"
  #         }
  #         memory_reservation = 50
  #       }

  #       ecs-sample = {
  #         cpu       = 512
  #         memory    = 1024
  #         essential = true
  #         image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"
  #         port_mappings = [
  #           {
  #             name          = "ecs-sample"
  #             containerPort = 80
  #             protocol      = "tcp"
  #           }
  #         ]

  #         # Example image used requires access to write to root filesystem
  #         readonly_root_filesystem = false

  #         dependencies = [{
  #           containerName = "fluent-bit"
  #           condition     = "START"
  #         }]

  #         enable_cloudwatch_logging = false
  #         log_configuration = {
  #           logDriver = "awsfirelens"
  #           options = {
  #             Name                    = "firehose"
  #             region                  = "eu-west-1"
  #             delivery_stream         = "my-stream"
  #             log-driver-buffer-limit = "2097152"
  #           }
  #         }
  #         memory_reservation = 100
  #       }
  #     }

  #     service_connect_configuration = {
  #       namespace = "example"
  #       service = {
  #         client_alias = {
  #           port     = 80
  #           dns_name = "ecs-sample"
  #         }
  #         port_name      = "ecs-sample"
  #         discovery_name = "ecs-sample"
  #       }
  #     }

  #     load_balancer = {
  #       service = {
  #         target_group_arn = "arn:aws:elasticloadbalancing:eu-west-1:1234567890:targetgroup/bluegreentarget1/209a844cd01825a4"
  #         container_name   = "ecs-sample"
  #         container_port   = 80
  #       }
  #     }

  #     subnet_ids = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  #     security_group_rules = {
  #       alb_ingress_3000 = {
  #         type                     = "ingress"
  #         from_port                = 80
  #         to_port                  = 80
  #         protocol                 = "tcp"
  #         description              = "Service port"
  #         source_security_group_id = "sg-12345678"
  #       }
  #       egress_all = {
  #         type        = "egress"
  #         from_port   = 0
  #         to_port     = 0
  #         protocol    = "-1"
  #         cidr_blocks = ["0.0.0.0/0"]
  #       }
  #     }
  #   }
  # }

  # tags = {
  #   Environment = "Development"
  #   Project     = "Example"
  # }
}

resource "aws_ecs_task_definition" "Django-API" {
  depends_on = [ aws_vpc_endpoint_service.ecr_api_endpoint, aws_vpc_endpoint_service.ecr_dkr_endpoint ]
  family                   = "Django-API"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # For Fargate, awsvpc is obligatory
  # For cpu and memory, see: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html#fargate-tasks-size
  cpu                      = 256 # As our example app is simple, a cheap one is fine
  memory                   = 512
  execution_role_arn       = aws_iam_role.environment_role.arn
  container_definitions    = jsonencode(
  [
    {
      "name" = "${var.environment}" # The same name as the production image
      "image" = "${var.aws_account_number}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.environment}:${var.image_tag}" # Copy from the docker push *** command
      "cpu" = 256 # The values should be equal (better) or less than the ones set in the ecs task definition
      "memory" = 512
      "essential" = true
      "portMappings" = [
        {
          "containerPort" = 8000 # Recommended to use the ports defined in the security groups, ALB, etc
          "hostPort" = 8000
        }
      ]
    }
  ]
)


  # runtime_platform {
  #   operating_system_family = "WINDOWS_SERVER_2019_CORE"
  #   cpu_architecture        = "X86_64"
  # }
}

resource "aws_ecs_service" "Django-APIService" {
  depends_on = [ aws_vpc_endpoint_service.ecr_api_endpoint, aws_vpc_endpoint_service.ecr_dkr_endpoint ]
  name            = "Django-APIService"
  cluster         = module.ecs.cluster_id # cluster_id used to be ec_cluster_id
  task_definition = aws_ecs_task_definition.Django-API.arn # The task definition above
  desired_count   = 3 # Places 1 in each AZ to improve reliability / availability
  # iam_role        = aws_iam_role.foo.arn # As we defined at task definition, it is unnecessary
  # depends_on      = [aws_iam_role_policy.foo] # Not necessary in our example project

  # ordered_placement_strategy {
  #   type  = "binpack"
  #   field = "cpu"
  # }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target.arn # Go to ALB.tf to find and use the aws_alb_target_group
    container_name   = "${var.environment}" # The same name at task definition, container definitions
    container_port   = 8000
  }

  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  # }

  network_configuration { # As we are using Fargate, it is obligatory. Documentation: (Optional) Network configuration for the service. This parameter is required for task definitions that use the awsvpc network mode to receive their own Elastic Network Interface, and it is not supported for other network modes.
    subnets          = module.vpc.private_subnets # See VPC module
    security_groups  = [aws_security_group.privatenet.id, aws_security_group.vpc_endpoint_service.id] # See SecurityGroup.tf, Private Subnet security group
  }

  capacity_provider_strategy { # (Optional, but recommended use) Capacity provider strategies to use for the service. Can be one or more. These can be updated without destroying and recreating the service only if force_new_deployment = true and not changing from 0 capacity_provider_strategy blocks to greater than 0, or vice versa. Conflicts with launch_type.
    capacity_provider = "FARGATE"
    # base              = 1 #(Optional) Number of tasks, at a minimum, to run on the specified capacity provider. Only one capacity provider in a capacity provider strategy can have a base defined. Default is 0.
    weight            = 1 # (Required) Relative percentage of the total number of launched tasks that should use the specified capacity provider.
  }
}

