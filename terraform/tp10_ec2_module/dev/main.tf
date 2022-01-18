module "tp10_dev" {
  source        = "../modules/ec2"
  instance_type = "t2.nano"
  admin         = "chris"
  env           = "dev"
  key_name      = "christophe-kp"
}