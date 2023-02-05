provider "aws" {
    region = "us-east-1"
    access_key = ""
    secret_key = ""
}

#Exercises

# variable "subnet-prefix" {
#     description = "value"
#     default = "10.0.1.0/24"
#     type = string
# }

resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    tag = {
        Name = "production"
    }
}

resource "aws_internet_gateway" "gw"{
    vpc_id = aws_vpc.prod-vpc.id
    tags = {
        Name= "main"
    }
}

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod-route-table"
  }
}

resource "aws_subnet" "subnet-1"{
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.subnet-prefix
    availability_zone = "us-east-1a"
    tags = {
        Name = "prod-subnet"
    }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}


resource "aws_security_group" "allow-web" {
  name        = "allow_web_traffic"
  description = "Allow WEB inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 447
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
    ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
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
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "web-server-mic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow-web.id]
}

output "server_public_ip" {
    #show the value of aws_eip in aws
    value = aws_eip.one.public_ip
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-mic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}


resource "aws_instance" "web-instance" {
    ami = "ami-xxxx"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "main-key"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-mic.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
    tags = {
        Name = "web-server"
    }
}


#Examples 

# resource "aws_instance" "web" {
#     ami = "ami-0aa7d40eeae50c9a9"
#     instance_type = "t2.micro"
#     tags = {
#         Name = "ubuntu"
#     }
# }

# resource "aws_vpc" "first-vpc" {
#     cidr_block = "10.0.0.0/16"
#     tags = {
#         Name ="production"
#     }
# }

# resource "aws_vpc" "second-vpc" {
#     cidr_block = "10.1.0.0/16"
#     tags = {
#         Name ="development"
#     }
# }

# resource "aws_vpc" "subnet-1" {
#     vpc_id     = aws_vpc.first-vpc.id
#     cidr_block = "10.0.0.0/24"

#     tags = {
#         Name = "prod-subnet"
#     }
# }

# resource "aws_vpc" "subnet-2" {
#     vpc_id     = aws_vpc.second-vpc.id
#     cidr_block = "10.1.1.0/24"

#     tags = {
#         Name = "dev-subnet"
#     }
# }