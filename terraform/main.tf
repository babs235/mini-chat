# VPC - Mon réseau virtuel privé sur AWS
resource "aws_vpc" "mini_chat_vpc" {
  cidr_block           = "10.0.0.0/16" # 65,536 IPs disponibles
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mini-chat-vpc"
  }
}

# Subnet public - où je mets mon serveur EC2 (accessible depuis Internet)
resource "aws_subnet" "mini_chat_public_subnet" {
  vpc_id                  = aws_vpc.mini_chat_vpc.id
  cidr_block              = "10.0.1.0/24" # 256 IPs
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true # Attribue automatiquement une IP publique

  tags = {
    Name = "mini-chat-public-subnet"
  }
}

# Internet Gateway - la "porte" vers Internet pour mon VPC
resource "aws_internet_gateway" "mini_chat_igw" {
  vpc_id = aws_vpc.mini_chat_vpc.id

  tags = {
    Name = "mini-chat-igw"
  }
}

# Route table - indique comment sortir vers Internet
resource "aws_route_table" "mini_chat_public_rt" {
  vpc_id = aws_vpc.mini_chat_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mini_chat_igw.id
  }

  tags = {
    Name = "mini-chat-public-rt"
  }
}

# Association route table -> subnet
resource "aws_route_table_association" "mini_chat_public_rta" {
  subnet_id      = aws_subnet.mini_chat_public_subnet.id
  route_table_id = aws_route_table.mini_chat_public_rt.id
}


# Security Group - Mon pare-feu AWS (quels ports sont ouverts)
resource "aws_security_group" "mini_chat_sg" {
  name        = "mini-chat-sg"
  description = "Security group pour Mini-Chat"
  vpc_id      = aws_vpc.mini_chat_vpc.id

  # SSH - pour me connecter au serveur (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # À restreindre en prod !
  }

  # Application - port 3000 (backend)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus - port 9090 (métriques)
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana - port 3001 (dashboards)
  ingress {
    from_port   = 3001
    to_port     = 3001
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

  # Sortie vers Internet (pour télécharger Docker images, etc.)
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

# Data source pour chercher l'AMI Ubuntu 22.04 automatiquement
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instance EC2 - Mon serveur applicatif
resource "aws_instance" "mini_chat_ec2" {
  ami                    = data.aws_ami.ubuntu.id # AMI trouvée automatiquement
  instance_type          = "t3.micro"             # Gratuit (free tier)
  key_name               = var.key_name           # Clé SSH
  vpc_security_group_ids = [aws_security_group.mini_chat_sg.id]
  subnet_id              = aws_subnet.mini_chat_public_subnet.id

  user_data = file("${path.module}/user-data.sh") # Script d'init

  tags = {
    Name = "mini-chat-server"
  }
}

# Subnet privé pour RDS (base de données non exposée sur Internet)
resource "aws_subnet" "mini_chat_private_subnet" {
  vpc_id            = aws_vpc.mini_chat_vpc.id
  cidr_block        = "10.0.2.0/24" # 256 IPs privées
  availability_zone = "eu-west-3b"

  tags = {
    Name = "mini-chat-private-subnet"
  }
}

# RDS Subnet Group - groupe de subnets pour la base de données
resource "aws_db_subnet_group" "mini_chat_db_subnet_group" {
  name       = "mini-chat-db-subnet-group"
  subnet_ids = [aws_subnet.mini_chat_public_subnet.id, aws_subnet.mini_chat_private_subnet.id]

  tags = {
    Name = "mini-chat-db-subnet-group"
  }
}

# Security Group pour RDS - seul l'EC2 peut se connecter à la BDD
resource "aws_security_group" "mini_chat_db_sg" {
  name        = "mini-chat-db-sg"
  description = "Security group pour RDS MySQL"
  vpc_id      = aws_vpc.mini_chat_vpc.id

  # MySQL - port 3306, uniquement depuis le VPC
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Seulement le VPC interne
  }

  tags = {
    Name = "mini-chat-db-sg"
  }
}

# Instance RDS MySQL - ma base de données managée
resource "aws_db_instance" "mini_chat_db" {
  identifier        = "mini-chat-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro" # Gratuit (free tier)
  allocated_storage = 20            # 20 Go
  storage_type      = "gp2"

  db_name  = "mini_chat"
  username = "root"
  password = var.db_password # Variable sensible

  vpc_security_group_ids = [aws_security_group.mini_chat_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.mini_chat_db_subnet_group.name

  skip_final_snapshot = true # Pas de snapshot final (pour tests)

  tags = {
    Name = "mini-chat-database"
  }
}