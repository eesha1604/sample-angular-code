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
