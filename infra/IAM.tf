resource "aws_iam_role" "environment_role" {
  name = "${var.IAMRole}_role" # Note: also initialize the IAMRole variable at variables.tf file to make it work.

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = ["ec2.amazonaws.com",
                     "ecs-tasks.amazonaws.com"]
        }
      },
    ]
  })

  # tags = {
  #   tag-key = "tag-value"
  # }
}

resource "aws_iam_role_policy" "ecs_ecr" {
  name = "ecs_ecr"
  role = aws_iam_role.environment_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken", # For ECR authentication
          "ecr:BatchCheckLayerAvailability", # Check layer availability of docker images
          "ecr:GetDownloadUrlForLayer", # Get url of docker image to download and utilize it
          "ecr:BatchGetImage", # Get image
          "logs:CreateLogStream", # Create logs
          "logs:PutLogEvents", # Create log events
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.IAMRole}_profile"
  role = aws_iam_role.environment_role.name
}