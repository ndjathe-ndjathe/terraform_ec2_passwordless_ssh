# Create keys with TLS Provider for servers and an additional key for SSH connection
resource "tls_private_key" "keys" {
  count     = var.server_count + 1
  provider  = tls.tls
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create an aws bastion key pair
resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion_key_pair"
  public_key = tls_private_key.keys[0].public_key_openssh
  tags = {
    Name = "Bastion Key Pair"
  }
}

# Create an aws app key pair
resource "aws_key_pair" "app" {
  count      = var.server_count - 1
  key_name   = "app_key_pair-${count.index + 1}"
  public_key = tls_private_key.keys[count.index + 1].public_key_openssh
  tags = {
    Name = "App server ${count.index + 1} Key Pair"
  }
}

# Choose amazon ami
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

# Create a security group to allow SSH connections
resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Open port for SSH traffic"

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
    market_type = var.bastion_market_type
    spot_options {
      max_price = var.bastion_market_price
    }
  }
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.bastion_key.key_name
  user_data = templatefile("external/user_data_bastion.sh.tpl", {
    public_key : tls_private_key.keys[var.server_count].public_key_openssh,
    private_key : tls_private_key.keys[var.server_count].private_key_pem
  })
  instance_type = var.bastion_instance_type
  tags = {
    Name = "Bastion-server"
  }
}

resource "aws_instance" "app_servers" {
  count = var.server_count - 1
  ami   = data.aws_ami.amazon_ami.id
  instance_market_options {
    market_type = var.app_market_type
    spot_options {
      max_price = var.app_market_price
    }
  }
  vpc_security_group_ids = [aws_security_group.ssh.id]
  instance_type          = var.app_instance_type
  key_name               = aws_key_pair.app[count.index].key_name
  user_data = templatefile("external/user_data_apps.sh.tpl", {
    public_key : tls_private_key.keys[var.server_count].public_key_openssh
  })
  tags = {
    Name = "App-server-${count.index}"
  }
}