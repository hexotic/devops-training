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
