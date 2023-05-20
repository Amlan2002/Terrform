terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
}

provider "aws" {
    region = "us-west-2"
    access_key = "AKIASOF3YW2YCL5LCGV7"
    secret_key = "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"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_main_cidr

  tags = {
    name = "main-vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.main_vpc.id
  count  = length(var.public_subnet_cidr)
  cidr_block = element(var.public_subnet_cidr,count.index)
  availability_zone = element(var.availability_zones,count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.main_vpc.id
  count  = length(var.private_subnet_cidr)
  cidr_block = element(var.private_subnet_cidr,count.index)
  availability_zone = element(var.availability_zones,count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route_table"
  }
}

resource "aws_route_table" "a" {
  count = length(var.public_subnet_cidr)
  subnet_id = element(aws_subnet.public_subnets[*].id,count.index)
  route_table_id = aws_route_table.public_rt.id  
}

resource "aws_security_group" "allow_rdp" {
  name = "allow_rdp"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    description = "rdp"
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    t0_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_rdp"
  }
}

resource "aws_instance" "public_servers" {
  ami = "ami-01304f6fedc0a3ca6"
  instance_type = "t2.micro"
  key_name = "wind"
  count = length(var.public_subnet_cidr)
  subnet_id = element(aws_subnet.public_subnets[*].id,count.index)
  vpc_security_group_ids = [aws_security_group.allow_rdp.id]

  tags = {
    Name = "public"
  }
}

resource "aws_instance" "private_servers" {
  ami = "ami-01304f6fedc0a3ca6"
  instance_type = "t2.micro"
  key_name = "wind"
  count = length(var.private_subnet_cidr)
  subnet_id = element(aws_subnet.private_subnets[*].id,count.index)
  vpc_security_group_ids = [aws_security_group.allow_rdp.id]

  tags = {
    Name = "private"
  }
}

resource "aws_db_instance" "rds" {
  identifier = "database-1"
  engine = "mysql"
  engine_version = "8.0.27"
  instance_class = "db.t2.micro"
  allocated_storage = "20"
  storage_type = "gp2"
  username = "admin"
  password = "admin1234"
  publicly_accessible = true
  skip_final_snapshot = true

  tags = {
    name = "rds"
  }
}