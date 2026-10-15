terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"     # AWS provider plugin source
      version = "~> 6.0"            # Provide the version of the AWS provider plugin to use
    }
  }
}

provider "aws" {           # Configure the AWS provider with the specified region
  region = "us-east-1"    # Set the AWS region to use for resources
  access_key = "**************"  # Replace with your AWS access key
  secret_key = "***************************"  # Replace with your AWS secret key
}
