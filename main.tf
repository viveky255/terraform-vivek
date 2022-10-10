provider "aws"{
    region = "ap-south-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}



resource "aws_vpc" "myapp_vpc" {
    cidr_block = var.vpc_cidr_block
    instance_tenancy     = "default"
    enable_dns_support   = "true"
    enable_dns_hostnames = "true"
    enable_classiclink   = "false"
    tags = {
      "Name" = "${var.env_prefix}-vpc"
    }
  
}

resource "aws_subnet" "myapp_subnet-1" {
    vpc_id = aws_vpc.myapp_vpc.id
    cidr_block = var.subnet_cidr_block
    map_public_ip_on_launch = "true"
    availability_zone = var.avail_zone
    tags = {
      "Name" = "${var.env_prefix}-subnet-1"
    }
  
}

resource "aws_internet_gateway" "myapp_igw" {
    vpc_id = aws_vpc.myapp_vpc.id

    tags = {
      "Name" = "${var.env_prefix}-igw"
    }
  
}
resource "aws_default_route_table" "myapp_rtb" {
  default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id

  route  {
    cidr_block ="0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }
  tags = {
    "Name" = "${var.env_prefix}-rtb"
  }
}

resource "aws_route_table_association" "myapp_rtb_subnet" {
    subnet_id = aws_subnet.myapp_subnet-1.id
    route_table_id = aws_default_route_table.myapp_rtb.id
  
}
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.myapp_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    "Name" = "${var.env_prefix}-sg"
  }
}



data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20220912"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  
}


output "aws_ami_id"{
value = data.aws_ami.ubuntu.id
} 

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}



resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.myapp_subnet-1.id
  vpc_security_group_ids =  [aws_default_security_group.default_sg.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true
  key_name = "linux testing-1"

  user_data = file("entrypoint-script.sh")

tags = {
    "Name" = "${var.env_prefix}-server"
  }
  
  
}

