output "public_ip" {
  value = [for ip in aws_instance.do1-server.*.public_ip : "http://${ip}"]
}