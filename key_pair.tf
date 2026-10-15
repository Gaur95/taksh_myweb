resource "aws_key_pair" "my_key_pair" {
  key_name   = var.key_name  # Specify the name of the key pair
  public_key = file("~/.ssh/id_rsa.pub")  # Specify the path to the public key file
  
}