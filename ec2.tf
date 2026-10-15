
resource "aws_instance" "web" {
   ami     = var.ami  # Specify the Amazon Machine Image (AMI) ID for the EC2 instance
   instance_type = var.instance_type        # Specify the instance type for the EC2 instance
   key_name = var.key_name            # Specify the name of the key pair to use for SSH access
    tags = {
        Name = "MyWebServer"  # Assign a name tag to the EC2 instance   
    }
   security_groups = [ "launch-wizard-2", "default" ]  # Specify the security groups to associate with the EC2 instance
provisioner "local-exec" {
  command = "echo ${self.public_ip} > public_ip.txt"  # Execute a local command to write the public IP address of the EC2 instance to a file
}
   connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install nginx -y",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]
  }
provisioner "file" {
    source      = "index.html"  # Specify the local file to upload to the EC2 instance
    destination = "/home/ubuntu/index.html"  # Specify the destination path on the EC2 instance
  }
}

