terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

########################################################

# Expected Deliverables:

# - Launch an EC2 instance using Terraform
# - Connect to the instance
# - Install Jenkins, Java and Python in the instance

# Deployment plan

# Deploy EC2 instance
# Create VPC 
# Security Group open ports 22, 8080
# Connect to instance and deploy software

# NOTE: Security credentials configured with aws-cli (aws configure)
# and saved in ~/.aws/credentials upon running tf script system asks 
# for profile and it is "default". For unattended run use "terraform apply -var profile=default -auto-approve"
# NOTE2: Software post-install running with script.sh 

########################################################
#######  1. EC2 Deployment
########################################################

provider "aws" {
   profile    = "${var.profile}"
   region     = "${var.region}"
}

resource "aws_instance" "webserver" {
  ami           = "ami-08333bccc35d71140"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.devops-public1.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_ports.id}"]
  key_name = "jenkins"

# Copying the script.sh

provisioner "file" {
    source = "script.sh"
    destination = "/tmp/script.sh"
    connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/jenkins.pem")
    host        = self.public_ip
    }
}

# Execute script.sh and installing Jemkins with dependencies 

provisioner "remote-exec" {
   connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/jenkins.pem")
    host        = self.public_ip
   }
   inline=[
    "chmod +x /tmp/script.sh",
    "sudo /tmp/script.sh"
   ]
}
  
  tags = {
    Name = "jenkins_srv"
  }
}

########################################################
#######  2. Create VPC,Subnet,Route Table, Access Gateway
########################################################

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "devops_net"
  }
}

resource "aws_subnet" "devops-public1" {
   vpc_id            = aws_vpc.main.id
   cidr_block        = "10.0.1.0/24"
   map_public_ip_on_launch = true
   depends_on = [aws_vpc.main]
   availability_zone = "us-east-2a"
   tags = {
     Name = "devops-public-1"
   }
 }

 resource "aws_subnet" "devops-private1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.4.0/24"
    map_public_ip_on_launch = "false"
    depends_on = [aws_vpc.main]
    availability_zone = "us-east-2a"
    tags = {
       Name = "devops-private1"
   }
}

# Internet GW
resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.main.id}"

    tags = {
        Name = "MainGW"
    }
}

# route associations public
resource "aws_route_table_association" "devops-public1" {
    subnet_id = "${aws_subnet.devops-public1.id}"
    route_table_id = "${aws_route_table.devops-public.id}"
}

# create route table
resource "aws_route_table" "devops-public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }
    tags = {
        Name = "devops-public"
    }
}

########################################################
#######  3. Security Group open ports 22, 8080
########################################################

resource "aws_security_group" "allow_ports" {
  name        = "allow_http_ssh"
  description = "Allow 8080,22 inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP 8080 from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

 ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_ssh"
  }
}




