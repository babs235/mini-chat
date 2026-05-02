# ============================================================
# main.tf — Réseau, sécurité et base de données
# ============================================================

# ── VPC ──────────────────────────────────────────────────────
resource "aws_vpc" "mini_chat_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "mini-chat-vpc" }
}

# ── SUBNETS ──────────────────────────────────────────────────
# 2 subnets publics (AZ différentes) requis par l'ALB
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

# 2 subnets privés pour RDS (AWS exige 2 AZ minimum)
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
# L'ALB accepte le trafic HTTP public
resource "aws_security_group" "alb_sg" {
  name        = "mini-chat-alb-sg"
  description = "ALB: HTTP public entrant"
  vpc_id      = aws_vpc.mini_chat_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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
# Les containers n'acceptent le trafic que depuis l'ALB
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

  # Sortie libre : reach ECR (HTTPS), RDS (3306), CloudWatch
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mini-chat-ecs-sg" }
}

# ── SECURITY GROUP : RDS ─────────────────────────────────────
# La base de données n'accepte MySQL que depuis les containers ECS
resource "aws_security_group" "db_sg" {
  name        = "mini-chat-db-sg"
  description = "RDS: MySQL entrant depuis ECS uniquement"
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

  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  skip_final_snapshot     = true
  monitoring_interval     = 0

  tags = { Name = "mini-chat-database" }
}
