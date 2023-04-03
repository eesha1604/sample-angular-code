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
resource "aws_elb" "load_balancer" {
  name               = "my-load-balancer"
  subnets            = var.elb_subnets
  security_groups    = [var.elb_security_group]
  idle_timeout       = 400
  connection_draining = true
  connection_draining_timeout = 300

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "HTTP"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = aws_acm_certificate.ssl_certificate.id
  }
}

# Create EC2 instances for each environment
resource "aws_instance" "web_instances" {
  count = length(var.environments)

  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
}
