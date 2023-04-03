# Terraform provider block for AWS
provider "aws" {
  access_key = "AKIAUBZGQEMJRQG4GVU5"
  secret_key = "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"
  region     = "ap-south-1"
}


variable "application_name" {
  type    = string
  default = "my-application"
}

variable "github_repository_name" {
  type    = string
  default = "my-github-repo"
}

variable "environments" {
  type    = list(string)
  default = ["devel", "stage", "prod"]
}

# Create S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "my-terraform-state-bucket"
  versioning {
    enabled = true
  }
}

# Create IAM user for Terraform
resource "aws_iam_user" "terraform_user" {
  name = "terraform-user"
}

resource "aws_iam_access_key" "terraform_access_key" {
  user = aws_iam_user.terraform_user.name
}

resource "aws_iam_policy" "terraform_policy" {
  name_prefix = "terraform-policy-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = "arn:aws:s3:::my-terraform-state-bucket/*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "route53:*",
          "acm:*",
          "iam:*",
          "cloudfront:*",
          "cloudwatch:*",
          "sns:*",
          "sqs:*",
          "logs:*",
          "lambda:*",
          "apigateway:*",
          "s3:*",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "terraform_user_policy" {
  user       = aws_iam_user.terraform_user.name
  policy_arn = aws_iam_policy.terraform_policy.arn
}

# Create SSL certificate using ACM
resource "aws_acm_certificate" "ssl_certificate" {
  domain_name       = "example.com"
  validation_method = "DNS"
}

# Create Elastic Load Balancer (ELB)
# resource "aws_elb" "load_balancer" {
#   name               = "my-load-balancer"
#   subnets            = var.elb_subnets
#   security_groups    = [var.elb_security_group]
#   idle_timeout       = 400
#   connection_draining = true
#   connection_draining_timeout = 300

#   listener {
#     instance_port     = 80
#     instance_protocol = "HTTP"
#     lb_port           = 80
#     lb_protocol       = "HTTP"
#   }

#   listener {
#     instance_port      = 80
#     instance_protocol  = "HTTP"
#     lb_port            = 443
#     lb_protocol        = "HTTPS"
#     ssl_certificate_id = aws_acm_certificate.ssl_certificate.id
#   }
# }

data "aws_ami" "myami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Creating Key-pair
resource "aws_key_pair" "tf-key" {
  key_name   = "terraform-keypair"
  public_key = file("${path.module}/id_rsa.pub")
}

# Create   EC2-Instance
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.myami.id
  instance_type          = var.minikube_type
  key_name               = aws_key_pair.tf-key.key_name
  vpc_security_group_ids = [aws_security_group.allow-rule.id]
  subnet_id              = aws_subnet.public_subnet.id
  user_data              = file("script.sh")

  tags = {
    Name = "ec2_instance"
  }
}

# Create Internet-Gateway
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "FinalProject-IGW"
  }
}


# Create public RouteTable
resource "aws_route_table" "public_routetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0" //use so subnet can connect to anywhere
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "FinalProject-Public_RouteTable"
  }
}

# Associate Public Subnet in->Public Route table
resource "aws_route_table_association" "Publicsubnet-associate" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_routetable.id
}

resource "aws_route53_zone" "example" {
  name = "devops-challenge-dev"
}


resource "aws_route53_record" "example" {
  name    = "example.com"
  type    = "A"
  zone_id = aws_route53_zone.example.zone_id

  alias {
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn = aws_acm_certificate.example.arn

  timeouts {
    create = "30m"
  }

  depends_on = [aws_route53_record.example]
}

# Create Security Group
resource "aws_security_group" "allow-rule" {
  name        = "allow_rule"
  description = "Allow inbound traffic"

  vpc_id = aws_vpc.myvpc.id

  dynamic "ingress" {
    for_each = var.port
    iterator = port_number
    content {

      description = "Allow Port ${port_number.value}"
      from_port   = port_number.value
      to_port     = port_number.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-terraform-sg"
  }
}

# Create VPC
resource "aws_vpc" "myvpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "FinalProject_VPC"
  }
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.public_subnets_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true //use to make the subnet public
  tags = {
    Name = "FinalProject-PublicSubnet"
  }
}

# Create Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.private_subnets_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false //use to make the subnet private
  tags = {
    Name = "FinalProject-PrivateSubnet"
  }
}


# Create EC2 instances for each environment
# resource "aws_instance" "web_instances" {
#   count = length(var.environments)

#   ami           = var.ami_id
#   instance_type = var.instance_type
#   key_name      = var.key_name
#   subnet_id     = var.subnet_id
# }
