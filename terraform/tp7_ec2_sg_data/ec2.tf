resource "aws_instance" "myec2" {
  tags = {
    Name      = "${var.admin}-ec2-terraform",
    formation = "Frazer",
    iac       = "terraform"
  }
  key_name      = "christophe-kp"
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type
  #  securitysecurity_groups = [ "${aws_security_group.ec2_sg.name}"]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}

data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning AMI (Amazon Linux 2)*"]
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#security_groups
resource "aws_security_group" "ec2_sg" {
  name        = "${var.admin}-sg"
  description = "Allow TLS and HTTP"
  # vpc_id = aws_vpc.main.id

  ingress {
    description      = "TLS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.admin}-sg-tp7"
  }
}

output "ami_data" {
  value = [data.aws_ami.app_ami.id, data.aws_ami.app_ami.name]
}