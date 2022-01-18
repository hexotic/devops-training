output "ec2_id" {
  value = aws_instance.ec2-mod.id
}

output "ec2_ami" {
  value = aws_instance.ec2-mod.ami
}

output "ec2_az" {
  value = aws_instance.ec2-mod.availability_zone
}