variable "admin" {
  default = "tpl"
}

variable "env" {
  default = ""
  type = string
}


variable "ami" {
  default = "ami-04505e74c0741db8d"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = ""
  type = string
}