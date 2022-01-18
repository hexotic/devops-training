resource "aws_instance" "myec2" {
  tags = {
    Name      = "${var.admin}-ec2-terraform",
    formation = "Frazer",
    iac       = "terraform"
  }
  key_name      = "christophe-kp"
  ami           = "ami-04505e74c0741db8d"
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get install -y nginx
              sudo systemctl enable nginx
              sudo systemctl start nginx
              EOF

  provisioner "local-exec" {
    command = "echo '${aws_instance.myec2.tags.Name} [PUBLIC IP : ${self.public_ip} , ID: ${self.id} , AZ: ${self.availability_zone}]' >> infos-ec2.txt"
  }
}

resource "aws_instance" "myec2_prov" {
  tags = {
    Name      = "${var.admin}-ec2-terraform-2",
    formation = "Frazer",
    iac       = "terraform"
  }
  key_name      = "christophe-kp"
  ami           = "ami-04505e74c0741db8d"
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  #  securitysecurity_groups = [ "${aws_security_group.ec2_sg.name}"]

  provisioner "local-exec" {
    command = "echo '${aws_instance.myec2.tags.Name} [PUBLIC IP : ${self.public_ip} , ID: ${self.id} , AZ: ${self.availability_zone}]' >> infos-ec2.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("/tmp/chris-kp.pem")
    host = self.public_ip
  }
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#security_groups
resource "aws_security_group" "ec2_sg" {
  name        = "${var.admin}-sg"
  description = "Allow TLS and HTTP"
  # vpc_id = aws_vpc.main.id

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
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
    Name = "${var.admin}-sg-tp8"
  }
}

resource "local_file" "ec2output" {
  content  = "This EC2 type: ${aws_instance.myec2.public_ip} ${aws_instance.myec2.id} ${aws_instance.myec2.availability_zone}"
  filename = "./ec2-parameters.txt"
}
output "instance_public_ip" {
  description = "Public IP"
  value       = aws_instance.myec2.public_ip
}