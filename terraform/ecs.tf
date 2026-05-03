# ── ECR ──────────────────────────────────────────────────────
# On récupère l'URL du registre existant (créé manuellement une fois)
data "aws_ecr_repository" "backend" {
  name = "mini-chat-backend"
}

# ── IAM : rôle d'exécution ECS ──────────────────────────────
# Ce rôle permet à ECS de puller l'image ECR et d'écrire les logs CloudWatch
# C'est différent du task role (qui lui donnerait des droits à l'appli elle-même)
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

# Politique AWS managée : droits ECR pull + écriture logs CloudWatch
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Droit supplémentaire : lire les secrets SSM au démarrage du container
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

# ── SSM PARAMETER STORE ──────────────────────────────────────
# Les secrets sont chiffrés ici — jamais en clair dans les variables d'environnement
# Les valeurs arrivent depuis GitHub Secrets via TF_VAR_*
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

# ── CLOUDWATCH LOGS ──────────────────────────────────────────
resource "aws_cloudwatch_log_group" "mini_chat" {
  name              = "/ecs/mini-chat-backend"
  retention_in_days = 7
}

# ── ECS CLUSTER ─────────────────────────────────────────────
resource "aws_ecs_cluster" "mini_chat" {
  name = "mini-chat-cluster"

  # Container Insights active les métriques avancées (RunningTaskCount, etc.)
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ── ECS TASK DEFINITION ──────────────────────────────────────
# La "recette" du container : image, CPU, RAM, variables, secrets, logs
resource "aws_ecs_task_definition" "backend" {
  family                   = "mini-chat-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "mini-chat-backend"
    image = "${data.aws_ecr_repository.backend.repository_url}:${var.image_tag}"

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    environment = [
      { name = "DB_HOST", value = aws_db_instance.mini_chat_db.address },
      { name = "DB_USER", value = "root" },
      { name = "DB_NAME", value = "mini_chat" },
      { name = "NODE_ENV", value = "production" }
    ]

    # Les secrets sont injectés depuis SSM au démarrage — jamais visibles dans les logs
    secrets = [
      { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn },
      { name = "JWT_SECRET", valueFrom = aws_ssm_parameter.jwt_secret.arn }
    ]

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

# ── ACM : certificat SSL ─────────────────────────────────────
resource "aws_acm_certificate" "mini_chat" {
  domain_name       = "chat.ibrahimbabikir.fr"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Attend que le CNAME de validation soit propagé avant de continuer
resource "aws_acm_certificate_validation" "mini_chat" {
  certificate_arn = aws_acm_certificate.mini_chat.arn

  timeouts {
    create = "30m"
  }
}

# ── ALB ──────────────────────────────────────────────────────
resource "aws_lb" "mini_chat" {
  name               = "mini-chat-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# target_type = "ip" est obligatoire avec Fargate (pas d'instance EC2 derrière)
resource "aws_lb_target_group" "backend" {
  name        = "mini-chat-backend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.mini_chat_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

# HTTP → redirige vers HTTPS (301)
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

# HTTPS → forward vers les containers ECS
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
# Maintient 1 container en vie et gère les rolling updates automatiquement
resource "aws_ecs_service" "backend" {
  name            = "mini-chat-backend"
  cluster         = aws_ecs_cluster.mini_chat.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    # assign_public_ip = true car sans NAT Gateway, le container ne peut pas joindre ECR
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "mini-chat-backend"
    container_port   = 3000
  }

  # Les deux listeners doivent exister avant que ECS démarre
  depends_on = [aws_lb_listener.http, aws_lb_listener.https]
}
