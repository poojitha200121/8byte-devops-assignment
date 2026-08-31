data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public_a.id
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.app.id]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app"
  }



  user_data = file("${path.module}/scripts/user-data.sh")

  user_data_replace_on_change = true

}