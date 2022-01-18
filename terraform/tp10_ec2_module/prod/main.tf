module "tp10_dev" {
  source        = "../modules/ec2"
  instance_type = "t2.micro"
  admin         = "chris"
  env           = "prod"
  key_name      = "christophe-kp"
}