resource "aws_eip" "eip-mod" {
  vpc = true

  tags = {
    Name = "${var.admin}-eip-${var.env}"
  }
}