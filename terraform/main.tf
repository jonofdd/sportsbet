resource "aws_vpc" "sportsbet_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.sportsbet_vpc.id

  tags = {
    Name = "sportsbet_vpc_igw"
  }
}

resource "aws_route_table" "sportsbet_rtb" {
  vpc_id = aws_vpc.sportsbet_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "sportsbet_vpc_rtb"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.sportsbet_rtb.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.sportsbet_rtb.id
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.sportsbet_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.sportsbet_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"
}

resource "aws_lb" "sportsbet_alb" {
  name               = "sportsbet-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  security_groups    = [aws_security_group.alb_sg.id]

  enable_deletion_protection = false

  access_logs {
    bucket  = local.alb-logs
    enabled = true
  }

  tags = {
    Name = "Sportsbet ALB"
  }
}

resource "aws_s3_bucket" "lb_logs" {
  bucket = local.alb-logs
}

resource "aws_s3_bucket_policy" "lb_logs_policy" {
  bucket = aws_s3_bucket.lb_logs.id

  policy = data.aws_iam_policy_document.lb_logs_policy.json
}

data "aws_iam_policy_document" "lb_logs_policy" {
  statement {
    sid = "lb_logs_policy"

    actions = [
      "s3:*",
    ]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::156460612806:root"
      ]
    }

    effect = "Allow"

    resources = [
      "arn:aws:s3:::${local.alb-logs}",
      "arn:aws:s3:::${local.alb-logs}/*"
    ]
  }

  statement {
    sid = "S3ServerAccessLogsPolicy"

    actions = [
      "s3:PutObject",
    ]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    effect = "Allow"

    resources = [
      "arn:aws:s3:::${local.alb-logs}",
      "arn:aws:s3:::${local.alb-logs}/*"
    ]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lb_logs_lifecycle" {
  bucket = aws_s3_bucket.lb_logs.id

  rule {
    id     = "log"
    status = "Enabled" # Correct from "enabled = true" to "status = 'Enabled'"

    expiration {
      days = 90
    }
  }
}

resource "aws_cloudwatch_log_group" "sportsbet_logs" {
  name              = "sportsbet-service-cloudwatch"
  retention_in_days = 14 # Adjust based on how long you want to retain the logs
}

resource "aws_cloudwatch_dashboard" "sportsbet_dashboard" {
  dashboard_name = "SportsBet-Dashboard"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ClusterName", "${aws_ecs_cluster.sportsbet_cluster.name}", "ServiceName", "${aws_ecs_service.sportsbet_service.name}"],
          [".", "MemoryUtilization", ".", ".", ".", "."]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "eu-west-1",
        "stat": "Average",
        "period": 300,
        "title": "ECS Task Metrics"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "${aws_lb.sportsbet_alb.arn}", { "stat": "Sum", "period": 60 }],
          ["...", "HTTPCode_Target_3XX_Count"],
          ["...", "HTTPCode_Target_4XX_Count"],
          ["...", "HTTPCode_Target_5XX_Count"]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "eu-west-1",
        "title": "ALB HTTP Response Codes"
      }
    }
  ]
}
EOF
}

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.sportsbet_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // Allow all inbound HTTP traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] // Allow all outbound traffic
  }
}

resource "aws_lb_target_group" "sportsbet_tg" {
  name        = "sportsbet-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.sportsbet_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.sportsbet_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sportsbet_tg.arn
  }
}

resource "aws_security_group" "sportsbet_security_group" {
  vpc_id = aws_vpc.sportsbet_vpc.id

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
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "sportsbet_definition" {
  family                   = "sportsbet-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "sportsbet-web-server",
      "image" : "${data.aws_ecr_repository.sportsbet-ecr-repo.repository_url}:${var.image_name}",
      "cpu" : 256,
      "memory" : 512,
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort" : 80
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.sportsbet_logs.name,
          "awslogs-region" : "eu-west-1", // Specify the appropriate AWS region
          "awslogs-stream-prefix" : "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_cluster" "sportsbet_cluster" {
  name = "sportsbet-cluster"
}

resource "aws_ecs_service" "sportsbet_service" {
  name            = "sportsbet-service"
  cluster         = aws_ecs_cluster.sportsbet_cluster.id
  task_definition = aws_ecs_task_definition.sportsbet_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.sportsbet_tg.arn
    container_name   = "sportsbet-web-server"
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.alb_sg.id]
  }

  depends_on = [
    aws_lb_listener.http_listener
  ]


}

output "alb_dns_name" {
  value = aws_lb.sportsbet_alb.dns_name
}