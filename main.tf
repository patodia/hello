# Define the provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Create a route table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Associate route table with the subnet
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Create a Security Group
resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an S3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "my-unique-bucket-name"
  acl    = "private"
}

# Create an EFS file system
resource "aws_efs_file_system" "efs" {
  creation_token = "my-efs-token"
}

# Create an EFS mount target
resource "aws_efs_mount_target" "efs_mount" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.main.id
  security_groups = [aws_security_group.main.id]
}

# Create an Elastic IP
resource "aws_eip" "main" {
  vpc = true
}s

# Create an EC2 instance
resource "aws_instance" "main" {
  ami                         = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type               = "t2.micro"
  key_name                    = "my-key-pair"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.main.id]
  associate_public_ip_address = true
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 8
  }

  user_data = <<-EOF
              #!/bin/bash
              yum install -y amazon-efs-utils
              mkdir /data/test
              mount -t efs -o tls ${aws_efs_file_system.efs.id}:/ /data/test
              EOF

  tags = {
    Name = "EFS-EC2"
  }
}

# Associate the Elastic IP with the EC2 instance
resource "aws_eip_association" "main" {
  instance_id   = aws_instance.main.id
  allocation_id = aws_eip.main.id
}

# Output the resources' information
output "s3_bucket_id" {
  value = aws_s3_bucket.bucket.id
}

output "efs_volume_id" {
  value = aws_efs_file_system.efs.id
}

output "ec2_instance_id" {
  value = aws_instance.main.id
}

output "security_group_id" {
  value = aws_security_group.main.id
}

output "subnet_id" {
  value = aws_subnet.main.id
}
