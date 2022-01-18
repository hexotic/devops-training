resource "aws_instance" "myec2" {
  tags = {
    Name      = "ec2-${var.env}-${var.admin}",
    formation = "Frazer",
    iac       = "terraform"
  }
  key_name      = var.key_name
  ami           = var.ami
  instance_type = var.instance_type

  #  securitysecurity_groups = [ "${aws_security_group.ec2_sg.name}"]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}

# resource "aws_eip" "my_eip" {
#   vpc      = true
#   instance = aws_instance.myec2.id
# }

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
    Name = "${var.admin}-sg-tp10"
  }
}
