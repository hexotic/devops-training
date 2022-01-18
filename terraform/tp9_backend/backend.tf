terraform {
  backend "s3" {
    bucket = "chris-bucket-ajc"
    key    = "tp9.tfstate"
    region = "us-east-1"
  }
}