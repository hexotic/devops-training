resource "aws_instance" "myec2" {
  tags = {
    Name      = "chris-ec2-terraform",
    formation = "Frazer",
    iac       = "terraform"
  }
  key_name      = "christophe-kp"
  ami           = var.ami
  instance_type = "${data.local_file.ec2_info.content}"
}

data "local_file" "ec2_info" {
  filename = "./infos.txt"
}
