# ============================================================
# main.tf - "Qu'est-ce qu'on construit sur AWS ?"
# ============================================================
# Ce fichier décrit TOUTE l'infrastructure :
#   1. VPC (réseau privé)
#   2. Subnets (public + 2 privés)
#   3. Internet Gateway + Route Table
#   4. Security Groups (pare-feu)
#   5. Rôle IAM pour SSM (connexion sans SSH)
#   6. Instance EC2 (serveur)
#   7. RDS MySQL (base de données)
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

  # ❌ PAS de port 22 (SSH) → On utilise SSM Session Manager à la place
  # ❌ PAS de port 9090 (Prometheus) → Accessible uniquement via SSH tunnel
  # ❌ PAS de port 3001 (Grafana) → Accessible uniquement via SSH tunnel

  # Application - port 3000 (backend Node.js)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Accessible depuis Internet (c'est l'application)
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

  # Sortie vers Internet (pour télécharger Docker images, npm install, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 = tous les protocoles
    cidr_blocks = ["0.0.0.0/0"] # Tout le trafic sortant autorisé
  }

  tags = {
    Name = "mini-chat-sg"
  }
}

# Security Group pour RDS (la base de données)
# ⚠️ SEULEMENT le VPC interne peut se connecter → PAS Internet
resource "aws_security_group" "mini_chat_db_sg" {
  name        = "mini-chat-db-sg"
  description = "Security group for RDS MySQL - VPC access only"
  vpc_id      = aws_vpc.mini_chat_vpc.id

  # MySQL - port 3306, uniquement depuis le VPC interne
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Seulement les IPs du VPC (pas Internet !)
  }

  # Sortie (RDS a besoin de se connecter à AWS pour les mises à jour)
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
# 5. Rôle IAM pour SSM Session Manager
# ────────────────────────────────────────────────────────────
# Rappel :
#   IAM Role = un "badge d'accès" que l'instance EC2 porte
#   SSM = AWS Systems Manager = service pour gérer les serveurs à distance
#   Avec SSM, tu te connectes SANS ouvrir le port SSH (22)
#   → Fonctionne depuis n'importe quel WiFi (maison, école, etc.)

# Rôle IAM que l'instance EC2 va "porter"
resource "aws_iam_role" "mini_chat_ssm_role" {
  name = "mini-chat-ssm-role"

  # Politique d'approbation = "Qui peut utiliser ce rôle ?"
  # Ici : seulement les instances EC2
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com" # Seules les instances EC2 peuvent prendre ce rôle
        }
      }
    ]
  })
}

# Attacher la policy SSM au rôle
# AmazonSSMManagedInstanceCore = permission d'utiliser Session Manager
resource "aws_iam_role_policy_attachment" "mini_chat_ssm_policy" {
  role       = aws_iam_role.mini_chat_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Profil d'instance = le "porte-badge" qu'on attache à EC2
resource "aws_iam_instance_profile" "mini_chat_ssm_profile" {
  name = "mini-chat-ssm-profile"
  role = aws_iam_role.mini_chat_ssm_role.name
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
  ami           = data.aws_ami.ubuntu.id # Image Ubuntu trouvée ci-dessus
  instance_type = "t3.small"             # 2 vCPU, 2 Go RAM
  # key_name               = var.key_name               # ❌ Inutile avec SSM Session Manager
  subnet_id              = aws_subnet.mini_chat_public_subnet.id               # Dans le subnet public
  vpc_security_group_ids = [aws_security_group.mini_chat_sg.id]                # Pare-feu EC2
  iam_instance_profile   = aws_iam_instance_profile.mini_chat_ssm_profile.name # Badge SSM

  user_data = file("${path.module}/user-data.sh") # Script de démarrage

  tags = {
    Name = "mini-chat-server"
  }
}


# ────────────────────────────────────────────────────────────
# 7. RDS MySQL - La base de données managée
# ────────────────────────────────────────────────────────────
# Rappel :
#   RDS = base de données gérée par AWS (sauvegardes auto, mises à jour auto)
#   db.t3.micro = instance gratuite (free tier)
#   ⚠️ La BDD est dans 2 subnets PRIVÉS dans 2 AZ différentes (haute dispo)

# RDS Subnet Group - groupe de subnets pour la base de données
# ⚠️ CORRECTION DU PROF : 2 subnets PRIVÉS dans 2 AZ différentes
# (Avant : 1 public + 1 privé → MAUVAIS car la BDD était exposée)
resource "aws_db_subnet_group" "mini_chat_db_subnet_group" {
  name = "mini-chat-db-subnet-group"
  subnet_ids = [
    aws_subnet.mini_chat_private_subnet_1.id, # Privé en eu-west-3a
    aws_subnet.mini_chat_private_subnet_2.id, # Privé en eu-west-3c
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
  instance_class    = "db.t3.micro" # Free tier
  allocated_storage = 20            # 20 Go
  storage_type      = "gp2"

  db_name  = "mini_chat"
  username = "root"
  password = var.db_password # Variable sensible (dans terraform.tfvars)

  vpc_security_group_ids = [aws_security_group.mini_chat_db_sg.id] # Pare-feu RDS
  db_subnet_group_name   = aws_db_subnet_group.mini_chat_db_subnet_group.name

  # ──────────────────────────────────────────────────────────────────
  # BACKUP AUTOMATIQUE AWS RDS
  # ──────────────────────────────────────────────────────────────────
  # Rappel : Plus besoin du script manuel backup-mysql.sh
  # AWS fait tout automatiquement, tous les jours, sans intervention

  # Configuration du backup automatique (FREE TIER)
  backup_retention_period = 1             # Free tier = 1 jour maximum
  backup_window           = "03:00-04:00" # Backup à 3h du matin
  skip_final_snapshot     = true          # Free tier = pas de snapshot final
  snapshot_identifier     = null          # Pas de snapshot manuel au démarrage

  # Optionnel : Monitoring des backups
  monitoring_interval = 0 # Pas de monitoring détaillé (free tier)


  tags = {
    Name = "mini-chat-database"
  }
}


