variable "ami" {
  description = "Amazon Machine Image (AMI) ID for the EC2 instance"  # Description of the variable
  default     = "ami-0b6d9d3d33ba97d99"  # Default value for the AMI ID
}
variable "instance_type" {
  description = "Instance type for the EC2 instance"  # Description of the variable
  default     = "t3.micro"  # Default value for the instance type
}
variable "key_name" {
  description = "Name of the key pair to use for SSH access"  # Description of the variable
  default     = "myterra_key"  # Default value for the key pair name
}