resource "aws_instance" "ec2-mod" {
  tags = {
    Name = "${var.admin}-ec2-${var.env}",
    iac  = "terraform"
  }
  key_name      = var.key_name
  ami           = data.aws_ami.myami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.sg_id]
}

data "aws_ami" "myami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic*"]
  }
}