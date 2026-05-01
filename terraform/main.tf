# ============================================================
# main.tf - "Qu'est-ce qu'on construit sur AWS ?"
# ============================================================
# Ce fichier décrit TOUTE l'infrastructure :
#   1. VPC (réseau privé)
#   2. Subnets (public + 2 privés)
#   3. Internet Gateway + Route Table
#   4. Security Groups (pare-feu)
#   5. Instance EC2 (serveur)
#   6. RDS MySQL (base de données)
# ============================================================

# ────────────────────────────────────────────────────────────
# 1. VPC - Mon réseau virtuel privé sur AWS
# ────────────────────────────────────────────────────────────
# Rappel : VPC = comme un immeuble virtuel
# 10.0.0.0/16 = 65 536 adresses IP possibles
resource "aws_vpc" "mini_chat_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mini-chat-vpc"
  }
}

# ────────────────────────────────────────────────────────────
# 2. Subnets - Les étages de l'immeuble
# ────────────────────────────────────────────────────────────
# Rappel :
#   Subnet PUBLIC  = accessible depuis Internet (serveur web)
#   Subnet PRIVÉ   = PAS accessible depuis Internet (base de données)
#   /24 = 256 adresses IP

# Subnet PUBLIC - pour le serveur EC2 (accessible depuis Internet)
resource "aws_subnet" "mini_chat_public_subnet" {
  vpc_id                  = aws_vpc.mini_chat_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mini-chat-public-subnet"
  }
}

# Subnet PRIVÉ 1 - pour la base de données RDS
#  PAS d'IP publique = PAS accessible depuis Internet
resource "aws_subnet" "mini_chat_private_subnet_1" {
  vpc_id            = aws_vpc.mini_chat_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-3a" # Data center Paris A

  tags = {
    Name = "mini-chat-private-subnet-1"
  }
}

# Subnet PRIVÉ 2 - pour la base de données RDS (2ème AZ)
# AWS exige 2 subnets dans 2 zones différentes pour RDS
# Si un data center tombe en panne, l'autre prend le relais
resource "aws_subnet" "mini_chat_private_subnet_2" {
  vpc_id            = aws_vpc.mini_chat_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-3c" # Data center Paris C (DIFFÉRENT de A)

  tags = {
    Name = "mini-chat-private-subnet-2"
  }
}


# ────────────────────────────────────────────────────────────
# 3. Internet Gateway + Route Table
# ────────────────────────────────────────────────────────────
# Rappel :
#   Internet Gateway = la porte d'entrée vers Internet
#   Route Table = le panneau de direction ("pour aller sur Internet, prends cette porte")

# Internet Gateway - la "porte" vers Internet
resource "aws_internet_gateway" "mini_chat_igw" {
  vpc_id = aws_vpc.mini_chat_vpc.id

  tags = {
    Name = "mini-chat-igw"
  }
}

# Route Table - indique comment sortir vers Internet
resource "aws_route_table" "mini_chat_public_rt" {
  vpc_id = aws_vpc.mini_chat_vpc.id

  route {
    cidr_block = "0.0.0.0/0"                           # Tout le trafic Internet
    gateway_id = aws_internet_gateway.mini_chat_igw.id # → passe par l'Internet Gateway
  }

  tags = {
    Name = "mini-chat-public-rt"
  }
}

# Association : connecte le subnet public à la route table
resource "aws_route_table_association" "mini_chat_public_rta" {
  subnet_id      = aws_subnet.mini_chat_public_subnet.id
  route_table_id = aws_route_table.mini_chat_public_rt.id
}


# ────────────────────────────────────────────────────────────
# 4. Security Groups - Les pare-feux
# ────────────────────────────────────────────────────────────
# Rappel :
#   Ingress = qui peut ENTRER (se connecter à moi)
#   Egress  = qui peut SORTIR (vers qui je peux me connecter)
#   0.0.0.0/0 = tout le monde sur Internet 
#   10.0.0.0/16 = seulement mon VPC interne 

# Security Group pour EC2 (le serveur applicatif)
resource "aws_security_group" "mini_chat_sg" {
  name        = "mini-chat-sg"
  description = "Security group pour le serveur EC2 Mini-Chat"
  vpc_id      = aws_vpc.mini_chat_vpc.id

  # Application - port 3000 (backend Node.js)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP - port 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS - port 443
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH - port 22 (pour EC2 Instance Connect et SSH)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Sortie vers Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mini-chat-sg"
  }
}

# Security Group pour RDS (la base de données)
resource "aws_security_group" "mini_chat_db_sg" {
  name        = "mini-chat-db-sg"
  description = "Security group for RDS MySQL - VPC access only"
  vpc_id      = aws_vpc.mini_chat_vpc.id

  # MySQL - port 3306, uniquement depuis le VPC interne
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Sortie vers Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mini-chat-db-sg"
  }
}




# ────────────────────────────────────────────────────────────
# 6. Instance EC2 - Le serveur applicatif
# ────────────────────────────────────────────────────────────
# Rappel :
#   EC2 = un ordinateur virtuel que tu loues
#   AMI = l'image système (Ubuntu 22.04 ici)
#   user_data = script lancé au premier démarrage

# Chercher l'image Ubuntu 22.04 automatiquement
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical = l'entreprise qui fait Ubuntu

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# L'instance EC2
resource "aws_instance" "mini_chat_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  key_name     = "mini-chat-key"
  subnet_id    = aws_subnet.mini_chat_public_subnet.id
  vpc_security_group_ids = [aws_security_group.mini_chat_sg.id]

  user_data = <<-EOF
#!/bin/bash
apt-get update
apt-get install -y docker.io docker-compose-plugin awscli
usermod -aG docker ubuntu
systemctl enable docker && systemctl start docker
cd /home/ubuntu
git clone https://github.com/babs235/mini-chat.git
cd mini-chat/docker
cp .env.example .env
docker compose up -d
EOF

  tags = {
    Name = "mini-chat-server"
  }
}


# ────────────────────────────────────────────────────────────
# 7. RDS MySQL - La base de données managée
# ────────────────────────────────────────────────────────────

# RDS Subnet Group
resource "aws_db_subnet_group" "mini_chat_db_subnet_group" {
  name = "mini-chat-db-subnet-group"
  subnet_ids = [
    aws_subnet.mini_chat_private_subnet_1.id,
    aws_subnet.mini_chat_private_subnet_2.id,
  ]

  tags = {
    Name = "mini-chat-db-subnet-group"
  }
}

# Instance RDS MySQL
resource "aws_db_instance" "mini_chat_db" {
  identifier        = "mini-chat-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "mini_chat"
  username = "root"
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.mini_chat_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.mini_chat_db_subnet_group.name

  # Configuration du backup automatique (FREE TIER)
  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  skip_final_snapshot     = true
  snapshot_identifier     = null

  monitoring_interval = 0

  tags = {
    Name = "mini-chat-database"
  }
}


