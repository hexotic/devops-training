output "eip_ip" {
  value = aws_eip.eip-mod.public_ip
}

output "eip_id" {
  value = aws_eip.eip-mod.id
}