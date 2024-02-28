
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.13"
    }
  }
  required_version = " 1.7.4"
}
provider "aws" {
  region = "eu-west-3"
}

# Create a Security Group for an EC2 instance
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "example" {
  ami                    = "ami-03f12ae727bb56d85"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
	      #!/bin/bash
	      echo "Hello, World" > index.html
	      nohup busybox httpd -f -p 8080 &
	      EOF

  tags = {
    Name = "terraform-example"
  }
}

# Output variable: Public IP address
output "public_ip" {
  value = aws_instance.example.public_ip
}
