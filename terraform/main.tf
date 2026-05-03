# ── VPC ──────────────────────────────────────────────────────
resource "aws_vpc" "mini_chat_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "mini-chat-vpc" }
}

# ── SUBNETS ──────────────────────────────────────────────────
# L'ALB exige 2 subnets publics dans des AZ différentes
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.mini_chat_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true
  tags                    = { Name = "mini-chat-public-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.mini_chat_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-3c"
  map_public_ip_on_launch = true
  tags                    = { Name = "mini-chat-public-2" }
}

# RDS exige aussi 2 AZ minimum — ces subnets sont privés (pas d'IP publique)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.mini_chat_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-3a"
  tags              = { Name = "mini-chat-private-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.mini_chat_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-3c"
  tags              = { Name = "mini-chat-private-2" }
}

# ── INTERNET GATEWAY + ROUTES ────────────────────────────────
# Permet aux subnets publics de communiquer avec internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mini_chat_vpc.id
  tags   = { Name = "mini-chat-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.mini_chat_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "mini-chat-public-rt" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ── SECURITY GROUP : ALB ─────────────────────────────────────
# Ports 80 et 443 ouverts au public — tout le reste est bloqué
resource "aws_security_group" "alb_sg" {
  name        = "mini-chat-alb-sg"
  description = "ALB: HTTP et HTTPS entrant"
  vpc_id      = aws_vpc.mini_chat_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mini-chat-alb-sg" }
}

# ── SECURITY GROUP : ECS TASKS ───────────────────────────────
# Le container n'accepte du trafic que depuis l'ALB (pas directement depuis internet)
resource "aws_security_group" "ecs_sg" {
  name        = "mini-chat-ecs-sg"
  description = "ECS Fargate: trafic entrant depuis ALB uniquement"
  vpc_id      = aws_vpc.mini_chat_vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Sortie libre : nécessaire pour joindre ECR, RDS et CloudWatch
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mini-chat-ecs-sg" }
}

# ── SECURITY GROUP : RDS ─────────────────────────────────────
# MySQL accessible uniquement depuis les containers ECS — jamais depuis internet
resource "aws_security_group" "db_sg" {
  name        = "mini-chat-db-sg"
  description = "RDS MySQL: accès depuis ECS uniquement"
  vpc_id      = aws_vpc.mini_chat_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mini-chat-db-sg" }
}

# ── RDS MySQL ────────────────────────────────────────────────
# Le subnet group dit à RDS dans quels subnets il peut placer la base
resource "aws_db_subnet_group" "mini_chat" {
  name       = "mini-chat-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags       = { Name = "mini-chat-db-subnet-group" }
}

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

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.mini_chat.name

  # 1 jour de backup = limite du free tier (7 dépassait le quota)
  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  skip_final_snapshot     = true
  monitoring_interval     = 0

  tags = { Name = "mini-chat-database" }
}
