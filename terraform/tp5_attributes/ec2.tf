resource "aws_instance" "myec2" {
  tags = {
    Name      = "chris-ec2-terraform",
    formation = "Frazer",
    iac       = "terraform"
  }
  key_name      = "christophe-kp"
  ami           = var.ami
  instance_type = var.instance_type
}

output "my_ip" {
  value = aws_instance.myec2.public_ip
}

#resource "aws_eip" "ec2eip" {
#  instance = aws_instance.myec2.id
#  vpc      = true
#}

resource "local_file" "ec2outputfile" {
  filename = "./ec2-parameters.txt"
  content  = "This EC2 type: ${aws_instance.myec2.instance_type} - ami: ${aws_instance.myec2.ami}"
}