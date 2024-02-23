#How to deploy a Django application using Docker, AWS ECS and Terraform

## Requirements

-A DockerHub account
-A AWS account
-Python 3.8+
-Terraform 1.0+
-AWS CLI 2.4+

## Initial setup

We must manually create a S3 bucket. To do so, open the browser or Terminal and create a new bucket in your desired region. Copy the bucket name somewhere, we will use it later.

Create a Git and GitHub repository to store your changes.

At the project directory, create the following directories:

infra/

env/homolog/

env/prod/

Then see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
and https://developer.hashicorp.com/terraform/language/settings/backends/s3

At infra/, create a file named `Providers.tf`, and modify the region if necessary:

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}
```

Then at each environment, create `Backend.tf` files:

Homologation:

```terraform
terraform {
  backend "s3" {
    bucket = "<your bucket>"
    key    = "homolog/terraform.tfstate"
    region = "us-west-2"
  }
}
```

Production:

```terraform
terraform {
  backend "s3" {
    bucket = "<your bucket>"
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
  }
}
```

## Create Docker repository

See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository

At infra/, create a new file named `ECR.tf` :

```terraform
resource "aws_ecr_repository" "repository" {
  name = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

Also at infra/, create a new file named `Variables.tf` to initialize the variables:

```terraform
variable "repository_name" {
  type = string
}
```

Now at env/prod/ and env/homolog/ create new files named `Main.tf`:

For homolog/:

```terraform
module "prod" {
  source = "../../infra"

  repository_name = "homologation" # Always use lowercase letters, no special characters or numbers or it may not work properly.

  environment = "homolog"
}
```

For prod/:

```terraform
module "prod" {
  source = "../../infra"

  repository_name = "production" # Always use lowercase letters, no special characters or numbers or it may not work properly.

  environment = "prod"
}
```

Finally, add this block of code in your `variables.tf`:

```terraform
variable "environment" {
  type = string
}
```

### Create the initial ECR resources at AWS

Open the Terminal, at homolog/ or prod/, run:

```bash
terraform init
```

It is an important step to create the environment variable for Terraform state file and download the provider plugins.
Then you can plan and apply these commands:

```bash
terraform plan
terraform apply
```

### Push Docker image into ECR repository

#### Application

Ideally, we should separate application versions for each environment, test and homolog in one environment and only push approved code to the production environment.

Git clone the repository of your project to the project directory. E.g.:

```bash
git clone https://github.com/guilhermeonrails/clientes-leo-api
```

**NOTE: the repository above is just for learning/testing purposes. You should replace this URL with your own application's repository.**

Now put the application into a Docker image. Create a `Dockerfile` file in the folder of your cloned project.
Example:

`clientes-leo-api/Dockerfile`

Define the project components inside this Docker container. See the documentation:
[Docker samples documentation](https://docs.docker.com/samples/)

Python example:

```dockerfile
# syntax=docker/dockerfile:1.4

FROM --platform=$BUILDPLATFORM python:3.7-alpine AS builder
EXPOSE 8000
WORKDIR /app
COPY requirements.txt /app
RUN pip3 install -r requirements.txt --no-cache-dir
COPY . /app
ENTRYPOINT ["python3"]
CMD ["manage.py", "runserver", "0.0.0.0:8000"]

FROM builder as dev-envs
RUN <<EOF
apk update
apk add git
EOF

RUN <<EOF
addgroup -S docker
adduser -S --shell /bin/bash --ingroup docker vscode
EOF
# install Docker tools (cli, buildx, compose)
COPY --from=gloursdocker/docker / /
CMD ["manage.py", "runserver", "0.0.0.0:8000"]
```

Or the code in this project:

```dockerfile
# FROM --platform=$BUILDPLATFORM python:3.7-alpine AS builder
FROM  python:3
ENV PYTHONDONTWRITEBYTECODE=1
# Python don´t write bytecode as it is unnecessary for most projects using containarization.
ENV PYTHONUNBUFFERED=1
# Don´t use buffer as it is unnecessary for most projects using containarization.
WORKDIR /home/ubuntu/tcc/
# Work directory
COPY . /home/ubuntu/tcc/
# Copies everything to the work directory
RUN pip3 install -r requirements.txt --no-cache-dir
# Installs the libraries / required components
RUN sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/" setup/settings.py
# Allows to respond to any requests without having a specific domain name configured
RUN python3 manage.py migrate
# Database migration
RUN python manage.py loaddata clientes.json
# Load initial database data from json file
ENTRYPOINT python manage.py runserver 0.0.0.0:8000
# Run server on port 8000 of IP address 0.0.0.0
EXPOSE 8000
# Exposed the 8000 port
```

#### Build the image

Open the terminal and at the application directory (`clientes-leo-api/`), run:

For homologation environment:

```bash
docker build . -t homologation:v1
```

For production environment:

```bash
docker build . -t production:v1
```

You may change the image name to something more meaningful if you want. The `-f` flag can be used to specify another Dockerfile. The `-t` flag allows you to tag your image with an alias so that you can refer to it. This command will generate an image with the tag `production:v1`. `v1` refers to the production Dockerfile version 1.

#### Authenticate into AWS to be able to push

We must authenticate first to push the image into ECR repositories.

First adjust and then run the following command line arguments:

```bash
aws ecr get-login-password --region region | docker login --username AWS --password-stdin aws_account_id.dkr.ecr.region.amazonaws.com
```

Replace `region`, `aws_account_id` with your only numbers AWS account ID and the next `region`. E.g.

```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 646456456452.dkr.ecr.us-west-2.amazonaws.com
```

###### Possible errors:

**Error:**

```bash
aws permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/auth": dial unix /var/run/docker.sock: connect: permission denied
```

**Solution:**

If you want to run docker as non-root user then you need to add it to the docker group.

Create the docker group if it does not exist
$ sudo groupadd docker
Add your user to the docker group.
$ sudo usermod -aG docker $USER
Log in to the new docker group (to avoid having to log out / log in again; but if not enough, try to reboot):
$ newgrp docker
Check if docker can be run without root
$ docker run hello-world
$ sudo chmod 666 /var/run/docker.sock
Reboot if still got error

$ reboot

Warning

The docker group grants privileges equivalent to the root user. For details on how this impacts security in your system, see Docker Daemon Attack Surface.

Taken from the docker official documentation: manage-docker-as-a-non-root-user

**Error:**

```bash
Error saving credentials: error storing credentials - err: docker-credential-desktop resolves to executable in current directory (./docker-credential-desktop), out: ``
```

**Solution:**

In the file, `~/.docker/config.json`, change `credsStore` to `credStore` (note the missing s).

Explanation

The error seems to be introduced when moving from 'docker' to 'Docker Desktop', and vice-versa. In fact, Docker Desktop uses an entry credsStore, while Docker installed from apt uses credStore.

Extra

This solution also seems to work for the following, similar error:

Error saving credentials: error storing credentials - err: exec: "docker-credential-desktop":
executable file not found in $PATH, out: ``
which may occur when pulling docker images from a repository.


#### Run docker images and push them to the ECR

To see the list of the Docker images available on your system, you can use the following command:

```bash
docker images
```

Copy the IMAGE ID corresponding to the Docker image you want to pull and then proceed with the next steps below.

Adjust and run the following command accordingly with the IMAGE ID of the desired image, AWS account ID, region and repository:tag:

```bash
docker tag <IMAGE ID> <aws_account_id>.dkr.ecr.<us-west-2>.amazonaws.com/<my-repository:tag>
```

Example:

```bash
docker tag 5af3818676dc 646456456452.dkr.ecr.us-west-2.amazonaws.com/homologation:v1

docker tag 5af3818676dc 646456456452.dkr.ecr.us-west-2.amazonaws.com/production:v1
```

To confirm, run:

```bash
docker images
```

##### Docker push

Adjust and then run the following command:

```bash
docker push <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/<my-repository:tag>
```

Example:

```bash
docker push 646456456452.dkr.ecr.us-west-2.amazonaws.com/homologation:v1

docker push 646456456452.dkr.ecr.us-west-2.amazonaws.com/production:v1
```

Wait until the process is finished; it may take a few minutes to complete. You should now have an image in ECR that corresponds to your locally
built Docker image.

