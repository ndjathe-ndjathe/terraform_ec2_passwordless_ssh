terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.32.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}

provider "tls" {
  alias = "tls"
}

provider "aws" {
  region = "eu-west-3"
}

resource "tls_private_key" "keys" {
  count     = 3
  provider  = tls.tls
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion_key_pair"
  public_key = tls_private_key.keys[0].public_key_openssh
}

resource "aws_key_pair" "server_key" {
  key_name   = "server_key_pair"
  public_key = tls_private_key.keys[1].public_key_openssh
}

data "aws_ami" "amazon_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Opent port for SSH traffic"

  ingress {
    description      = "Allow SSH port"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow-ssh"
  }
}

resource "aws_instance" "bastion" {
  ami = data.aws_ami.amazon_ami.id
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0031
    }
  }
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.bastion_key.key_name
  user_data = templatefile("user_data_bastion.sh.tpl", {
    public_key : tls_private_key.keys[2].public_key_openssh,
    private_key : tls_private_key.keys[2].private_key_pem
  })
  instance_type = "t4g.nano"
  tags = {
    Name = "bastion"
  }
}

resource "aws_instance" "server" {
  ami = data.aws_ami.amazon_ami.id
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0031
    }
  }
  vpc_security_group_ids = [aws_security_group.ssh.id]
  instance_type          = "t4g.nano"
  key_name               = aws_key_pair.server_key.key_name
  user_data = templatefile("user_data.sh.tpl", {
    public_key : tls_private_key.keys[2].public_key_openssh
  })
  tags = {
    Name = "server"
  }
}

output "private_key" {
  value     = tls_private_key.keys[*].private_key_pem
  sensitive = true
}

output "public_key" {
  value = tls_private_key.keys[*].public_key_openssh
}