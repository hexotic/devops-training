module "mysg" {
  source = "../modules/sg"
  admin  = var.admin
  env    = var.env
}

module "myebs" {
  source = "../modules/ebs"
  admin  = var.admin
  env    = var.env
  az     = module.myec2.ec2_az
}

module "myeip" {
  source = "../modules/eip"
  admin  = var.admin
  env    = var.env
}

module "myec2" {
  source        = "../modules/ec2"
  instance_type = "t2.nano"
  key_name      = "christophe-kp"

  admin  = var.admin
  env    = var.env

  sg_id = module.mysg.sg_id
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = module.myec2.ec2_id
  allocation_id = module.myeip.eip_id
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.myebs.ebs_id
  instance_id = module.myec2.ec2_id
}

resource "local_file" "info" {
  filename = "ec2-info.txt"
  content  = module.myec2.ec2_id
}

resource "null_resource" "install-nginx" {
  depends_on = [
    aws_eip_association.eip_assoc
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/tmp/chris-kp.pem")
    host        = module.myeip.eip_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }
}

output "nginx_ip" {
  value = module.myeip.eip_ip
}