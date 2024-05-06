provider "aws" {
    region = "ap-south-1" 
}
terraform {
    backend "s3" {
        region = "ap-southe-1"
        bucket = "securefilebuck"
        key = "./terraform.tfstate"
    }
}
#creating vpc
resource "aws_vpc" "projectvpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "project-vpc" 
      env = "dev"
    }
}
#creating private subnet 
resource "aws_subnet" "project-private-subnet" {
    vpc_id = aws_vpc.projectvpc.id
    cidr_block = "10.0.0.0/20"
    tags = {
      Name = "project-private-subnet"
      env = "dev"
    } 
}
#creating public subnet 
resource "aws_subnet" "project-public-subnet" {
    vpc_id = aws_vpc.projectvpc.id
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true
    tags = {
      Name = "project-public-subnet"
      env =  "dev"
    }  
}
#creating internet gateway
resource "aws_internet_gateway" "project-igw" {
    vpc_id = aws_vpc.projectvpc.id
    tags = {
      Name = "project-igw"
      env = "dev"
    }
}
#creating nat gateway 
resource "aws_nat_gateway" "private-nat" {
    subnet_id = aws_subnet.project-public-subnet.id
    connectivity_type = "private"
    tags = {
      Name = "private-nat"
    }
}
#creating route table 
resource "aws_route" "public-route-table" {
    route_table_id = aws_vpc.projectvpc.default_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project-igw.id  
}
resource "aws_route_table" "private-nat-route-table" {
    vpc_id = aws_vpc.projectvpc.id
    route = {
        cidr_block = "10.0.0.0/16"
    }
}
resource "aws_route" "private-route-table" {
    route_table_id = aws_route_table.private-nat-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.private-nat.id
  
}
#associating subnet ids
resource "aws_route_table_association" "public-subnet-association" {
    subnet_id = aws_subnet.project-public-subnet.id
    route_table_id = aws_vpc.projectvpc.default_route_table_id
}
resource "aws_route_table_association" "private-subnet-association" {
    subnet_id = aws_subnet.project-private-subnet.id
    route_table_id = aws_route_table.private-nat-route-table.id
}
#creating security group
resource "aws_security_group" "project-sg" {
    name = "project-sg"
    description = "all tcp sg for project" 
    vpc_id = aws_vpc.projectvpc.id
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "-1"
        from_port = 0
        to_port = 0
    }
    egress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "-1"
        from_port = 0
        to_port = 0
    }
}
#creating private instances
resource "aws_instance" "DB-server" {
    ami = "ami-013e83f579886baeb"
    instance_type = "t2.small"
    key_name = "lallya"
    vpc_security_group_ids = [aws_security_group.project-sg.id]
    subnet_id = aws_subnet.project-private-subnet.id
    user_data = file("install_mariadb.sh")
}
resource "aws_instance" "app-server" {
    ami = "ami-013e83f579886baeb"
    instance_type = "t2.small"
    key_name = "lallya"
    vpc_security_group_ids = [aws_security_group.project-sg.id]
    subnet_id = aws_subnet.project-private-subnet.id
    user_data = file("install_tomcat.sh")
}
resource "aws_instance" "web-server" {
    ami = "ami-013e83f579886baeb"
    instance_type = "t2.small"
    key_name = "lallya"
    vpc_security_group_ids = [aws_security_group.project-sg.id]
    subnet_id = aws_subnet.project-private-subnet.id
    user_data = file("install_httpd.sh")
}
resource "aws_instance" "bashan-server" {
    ami = "ami-013e83f579886baeb"
    instance_type = "t2.small"
    key_name = "lallya"
    vpc_security_group_ids = [aws_security_group.project-sg.id]
    subnet_id = aws_subnet.project-public-subnet.id
}