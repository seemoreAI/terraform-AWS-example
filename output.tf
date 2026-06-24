output "public_ip" {
  value = aws_instance.do1-server.*.public_ip
}