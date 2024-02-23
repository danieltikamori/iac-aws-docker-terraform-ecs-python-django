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
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
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
      "name" = "production" # The same name as the production image
      "image" = "<YOUR AWS ID>.dkr.ecr.us-west-2.amazonaws.com/production:V1" # Copy from the docker push *** command
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