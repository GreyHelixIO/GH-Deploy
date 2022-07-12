resource "aws_ecs_task_definition" "gh_api_task" {
    family                   = "gh-api-task-${var.env}"
    container_definitions    = <<DEFINITION
    [
        {
        "name": "gh-api-task-${var.env}",
        "image": "${var.ecr_api_repo_url}:${local.current_api_image_tag}",
        "essential": true,
        "environment": [
            {
                "name": "NODE_ENV",
                "value": "${var.env}"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "gh-api-${var.env}"
            }
        },
        "portMappings": [
            {
                "containerPort": 80,
                "hostPort": 80
            },
            {
                "containerPort": 443,
                "hostPort": 443
            }
        ],
            "memory": 512,
            "cpu": 256
        }
    ]
    DEFINITION
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    memory                   = 512
    cpu                      = 256
    execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
    task_role_arn            = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
    name               = "ecsTaskExecutionRole_${var.env}"
    assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
    role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "gh_cluster" {
    name = "gh-cluster-${var.env}"
}

resource "aws_ecs_service" "gh_api_service" {
    name            = "gh-api-service-${var.env}"
    cluster         = aws_ecs_cluster.gh_cluster.id
    task_definition = "${aws_ecs_task_definition.cs_api_task.arn}"
    launch_type     = "FARGATE"
    desired_count   = 1
    deployment_minimum_healthy_percent = 0
    force_new_deployment = true
    network_configuration {
        subnets = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}"]
        assign_public_ip = true
        security_groups  = ["${aws_security_group.service_security_group.id}"]
    }
    load_balancer {
        target_group_arn = "${aws_lb_target_group.target_group.arn}"
        container_name   = "${aws_ecs_task_definition.cs_api_task.family}"
        container_port   = 80
    }
}

resource "aws_alb" "application_load_balancer" {
    name               = "gh-alb-${var.env}"
    load_balancer_type = "application"
    subnets = [
        "${aws_default_subnet.default_subnet_a.id}",
        "${aws_default_subnet.default_subnet_b.id}"
    ]

    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}
resource "aws_security_group" "load_balancer_security_group" {
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
}

resource "aws_security_group" "service_security_group" {
    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_lb_target_group" "target_group" {
    name        = "gh-target-group-${var.env}"
    port        = 80
    protocol    = "HTTP"
    target_type = "ip"
    vpc_id      = "${aws_default_vpc.default_vpc.id}"
    health_check {
        matcher = "200,301,302"
        path = "/"
        interval = 60
    }
}

resource "aws_lb_listener" "listener" {
    load_balancer_arn = "${aws_alb.application_load_balancer.arn}"
    port              = "80"
    protocol          = "HTTP"
    default_action {
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.target_group.arn}"
    }
}

resource "aws_cloudwatch_log_group" "log-group" {
    name = "gh-api-logs-${var.env}"

    tags = {
        Application = "gh-api-${var.env}"
        Environment = var.env
    }
}

resource "aws_default_vpc" "default_vpc" {
    tags = {
        Name = "Default VPC"
    }
}

resource "aws_default_subnet" "default_subnet_a" {
    availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
    availability_zone = "us-east-1b"
}
locals {
    ecs_servcie_secrets = var.env == "prod" ? "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-api-config-prod-wvQqls" : "arn:aws:secretsmanager:us-east-1:455667379642:secret:gh-api-config-qa-E73Reo"
    current_api_image_tag = jsondecode(var.current_api_image_tag)["imageTags"][0]
}

data "aws_secretsmanager_secret" "gh_service_secrets" {
    arn = local.ecs_servcie_secrets
}

data "aws_secretsmanager_secret_version" "current" {
    secret_id = data.aws_secretsmanager_secret.cs_service_secrets.id
}