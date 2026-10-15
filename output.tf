output "public_ip" {
  value = aws_instance.web.public_ip  # Output the public IP address of the created EC2 instance
}
output "private_ip" {
  value = aws_instance.web.private_ip  # Output the private IP address of the created EC2 instance
}
output "key_name" {
  value = aws_instance.web.key_name  # Output the name of the key pair used for SSH access
}