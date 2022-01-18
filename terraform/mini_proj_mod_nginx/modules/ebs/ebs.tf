resource "aws_ebs_volume" "ebs-mod" {
  size = var.size
  availability_zone = "${var.az}"

  tags = {
    Name = "${var.admin}-ebs-${var.env}"
  }
}