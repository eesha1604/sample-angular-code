region               = "ap-south-1"
vpc_cidr             = "10.0.0.0/16"
public_subnets_cidr  = "10.0.1.0/24"
private_subnets_cidr = "10.0.0.0/24"
availability_zone    = "ap-south-1b"
minikube_type        = "t2.medium"
container_type       = "t2.micro"
port                 = [22, 80]
