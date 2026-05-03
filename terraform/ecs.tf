# ============================================================
# ecs.tf — Application : IAM, secrets, ECS Fargate, ALB
# ============================================================

# ── ECR : récupère l'URL du registre existant ────────────────
data "aws_ecr_repository" "backend" {
  name = "mini-chat-backend"
}

# ── IAM : rôle d'exécution ECS ──────────────────────────────
# Permet à ECS de puller l'image ECR et d'écrire les logs CloudWatch
resource "aws_iam_role" "ecs_execution_role" {
  name = "mini-chat-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Politique AWS managée : ECR pull + CloudWatch logs
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Accès aux secrets SSM (DB password, JWT secret)
resource "aws_iam_role_policy" "ecs_ssm_policy" {
  name = "mini-chat-ssm-secrets-access"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ssm:GetParameters"]
      Resource = [
        aws_ssm_parameter.db_password.arn,
        aws_ssm_parameter.jwt_secret.arn
      ]
    }]
  })
}

# ── SSM PARAMETER STORE : secrets chiffrés ──────────────────
# Les valeurs arrivent depuis les GitHub Secrets via TF_VAR_*
resource "aws_ssm_parameter" "db_password" {
  name  = "/mini-chat/db_password"
  type  = "SecureString"
  value = var.db_password
}

resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/mini-chat/jwt_secret"
  type  = "SecureString"
  value = var.jwt_secret
}

# ── CLOUDWATCH : logs des containers ────────────────────────
resource "aws_cloudwatch_log_group" "mini_chat" {
  name              = "/ecs/mini-chat-backend"
  retention_in_days = 7
}

# ── ECS CLUSTER ─────────────────────────────────────────────
resource "aws_ecs_cluster" "mini_chat" {
  name = "mini-chat-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ── ECS TASK DEFINITION ──────────────────────────────────────
# La "recette" du container : image, CPU, RAM, env vars, secrets, logs
resource "aws_ecs_task_definition" "backend" {
  family                   = "mini-chat-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB RAM
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "mini-chat-backend"
    image = "${data.aws_ecr_repository.backend.repository_url}:${var.image_tag}"

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    # Variables d'environnement non-sensibles
    environment = [
      { name = "DB_HOST", value = aws_db_instance.mini_chat_db.address },
      { name = "DB_USER", value = "root" },
      { name = "DB_NAME", value = "mini_chat" },
      { name = "NODE_ENV", value = "production" }
    ]

    # Secrets injectés depuis SSM au démarrage du container (jamais en clair)
    secrets = [
      { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn },
      { name = "JWT_SECRET", valueFrom = aws_ssm_parameter.jwt_secret.arn }
    ]

    # Logs visibles dans CloudWatch > /ecs/mini-chat-backend
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.mini_chat.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ── ALB : Application Load Balancer ─────────────────────────
resource "aws_lb" "mini_chat" {
  name               = "mini-chat-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# Target Group : l'ALB sait vers quels containers envoyer le trafic
resource "aws_lb_target_group" "backend" {
  name        = "mini-chat-backend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.mini_chat_vpc.id
  target_type = "ip" # Requis pour Fargate (pas d'instance EC2)

  health_check {
    path                = "/" # GET / → "Backend OK"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

# ── ACM : certificat SSL pour chat.ibrahimbabikir.fr ────────────
resource "aws_acm_certificate" "mini_chat" {
  domain_name       = "chat.ibrahimbabikir.fr"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "mini_chat" {
  certificate_arn = aws_acm_certificate.mini_chat.arn

  timeouts {
    create = "30m"
  }
}

# Listener HTTP : redirige tout le trafic vers HTTPS (301)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.mini_chat.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Listener HTTPS : trafic chiffré vers les containers ECS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.mini_chat.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.mini_chat.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# ── ECS SERVICE ──────────────────────────────────────────────
# Le "gardien" : maintient 1 container en vie, gère les rolling updates
resource "aws_ecs_service" "backend" {
  name            = "mini-chat-backend"
  cluster         = aws_ecs_cluster.mini_chat.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true # Nécessaire pour puller ECR sans NAT Gateway
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "mini-chat-backend"
    container_port   = 3000
  }

  # Le service attend que les deux listeners ALB soient prêts avant de démarrer
  depends_on = [aws_lb_listener.http, aws_lb_listener.https]
}
