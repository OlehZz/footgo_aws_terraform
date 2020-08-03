provider "aws" {
profile = "default"
region = "us-east-1"
}
# VPC footgo
resource "aws_vpc" "main" {
#    id = "aws_vpc.main.id"
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "main vpc footgo"
    }
}
#Subnets
resource "aws_subnet" "main-public-1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
    tags = {
        Name = "main-public-1"
    }
}
resource "aws_subnet" "main-private-1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "us-east-1a" 
    tags = {
        Name = "main-private-1"
    }
}
resource "aws_subnet" "main-private-2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "us-east-1b" 
    tags = {
        Name = "main-private-2"
    }
}
#Internet GW
resource "aws_internet_gateway" "main-gw" {
    vpc_id = aws_vpc.main.id   
    tags = {
        Name = "main-private-1"
    }
}
#eip for nat
resource "aws_eip" "nat" {
    vpc      = true
}
#NAT
resource "aws_nat_gateway" "nat-footgo" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.main-public-1.id
    tags = {
        Name = "nat-public-footgo"
    }
    depends_on = [aws_internet_gateway.main-gw]
}
#route tables GW
resource "aws_route_table" "main-public" {
    vpc_id = aws_vpc.main.id
route {    
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-gw.id
    }
    tags = {
        Name ="route-public-subnet"
    }
}
#route tables NAT
resource "aws_route_table" "nat-private-1" {
    vpc_id = aws_vpc.main.id
route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-footgo.id
    }
    tags = {
        Name ="NAT-subnet-1"
    }
}
resource "aws_route_table" "nat-private-2" {
    vpc_id = aws_vpc.main.id
route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-footgo.id
    }
    tags = {
        Name ="NAT-subnet-2"
    }
}
resource "aws_route_table_association" "nat_private-1" {
  route_table_id = aws_route_table.nat-private-1.id
  subnet_id = aws_subnet.main-private-1.id
}
resource "aws_route_table_association" "nat_private-2" {
  route_table_id = aws_route_table.nat-private-2.id
  subnet_id = aws_subnet.main-private-2.id
}
resource "aws_route_table_association" "gw_public_routes" {
  route_table_id = aws_route_table.main-public.id
  subnet_id = aws_subnet.main-public-1.id
}

#===============================================================
#create security group
resource "aws_security_group" "webserver" {
    name = "Webserver public"
    vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags = {
        Name = "Webserver public SG"
  }
}
#ec2 for ASG
resource "aws_launch_configuration" "web" {
    name            = "Webserver"
    key_name = "MyEC2 study1"
    image_id        = "ami-0ac80df6eff0e70b5"
    instance_type   = "t2.micro"
    security_groups = [aws_security_group.webserver.id]
}
# create ASG policy
resource "aws_autoscaling_policy" "web" {
    name                = "footgo_AS_policy"
    policy_type = "TargetTrackingScaling"
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
    target_value = 20.0
  }
    autoscaling_group_name = aws_autoscaling_group.webservers.name
}  
# Create ASG
resource "aws_autoscaling_group" "webservers" {
    name                 = "ASG webservers"
    launch_configuration = aws_launch_configuration.web.name
    min_size             = 1
    max_size             = 2
    desired_capacity     = 1
    health_check_type    = "EC2"
    vpc_zone_identifier  = [aws_subnet.main-public-1.id]
    force_delete              = true
}

#=============================================================================
#    description = "RDS security group
resource "aws_security_group" "mysql_rds_sg" {
    name = "mysql_rds_sg"
    vpc_id = aws_vpc.main.id  
    ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}
#db subnet group
resource "aws_db_subnet_group" "rds_mysql_private_subnet" {
  name       = "rds_mysql_private_subnet"
  subnet_ids = [aws_subnet.main-private-1.id, aws_subnet.main-private-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}
#create db
resource "aws_db_instance" "mysql_db" {
    allocated_storage    = 20
    storage_type         = "gp2"
    engine               = "mysql"
    engine_version       = "5.7"
    instance_class       = "db.t2.micro"
    db_subnet_group_name = aws_db_subnet_group.rds_mysql_private_subnet.name
    name                 = "footgo"
    vpc_security_group_ids = [aws_security_group.mysql_rds_sg.id]
    username             = "footgo"
    password             = "footgodb"
}