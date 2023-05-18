provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    User = "James Gollan",
    Creator = "terraform",
    owner_email = "jgollan@confluent.io"
  }
}

resource "aws_vpc" "cwd" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
    tags = merge(local.common_tags, {
    Name = "cwd-vpc"
  })
}

resource "aws_subnet" "cwd" {
  vpc_id     = aws_vpc.cwd.id
  cidr_block = "10.0.1.0/24"
  
  tags = merge(local.common_tags, {
    Name = "cwd-subnet"
  })
}

resource "aws_internet_gateway" "cwd" {
  vpc_id = aws_vpc.cwd.id

  tags = merge(local.common_tags, {
    Name = "cwd-gateway"
  })
}

resource "aws_route_table" "cwd" {
  vpc_id = aws_vpc.cwd.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cwd.id
  }

  tags = local.common_tags
}

resource "aws_route_table_association" "cwd" {
  subnet_id      = aws_subnet.cwd.id
  route_table_id = aws_route_table.cwd.id
}

resource "aws_security_group" "cwd_instance" {
  name_prefix = "cwd-instance"
  vpc_id      = aws_vpc.cwd.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
     
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_key_pair" "cwd" {
  key_name   = "cwd"
  public_key = file("~/.ssh/aws_rsa.pub")

  tags = local.common_tags
}

resource "aws_instance" "cwd" {
  ami                    = "ami-08c5a1ddde2cf26c2"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.cwd.id
  associate_public_ip_address = true
  key_name               = aws_key_pair.cwd.key_name
  vpc_security_group_ids = [aws_security_group.cwd_instance.id]

  tags = merge(local.common_tags, {
    Name = "cwd-instance"
  })

  provisioner "remote-exec" {
    inline = [
      "cd /home/ubuntu",
      "git clone https://github.com/gollyg/wordle.git",
      "echo 'export CLUSTER_CLOUD=\"aws\"' > /home/ubuntu/wordle/aws/app/env.config",
      "echo 'export CLUSTER_REGION=\"ap-southeast-2\"' >> /home/ubuntu/wordle/aws/app/env.config",
      "echo 'export YOUREMAIL=\"jgollan+org@confluent.io\"' >> /home/ubuntu/wordle/aws/app/env.config",
      "echo 'export WEBHOSTNAME=\"${aws_instance.cwd.public_dns}\"' >> /home/ubuntu/wordle/aws/app/env.config",
      "cd /home/ubuntu/wordle/aws/app",
      "./setup-cwd.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/aws_rsa")
    host        = self.public_ip
  }
}

