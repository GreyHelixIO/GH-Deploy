resource "aws_ecs_task_definition" "gh_task_definition" {
    family                   = "gh-${var.service}-task-${var.env}"
    container_definitions    = jsonencode([
        {
            name: "gh-${var.service}-task-${var.env}",
            image: "${var.ecr_repo_url}:${local.current_image_tag}",
            cpu: 256,
            memory: 512,
            essential: true,
            portMappings: [
                {
                    containerPort: 80,
                    hostPort: 80,
                },
                {
                    containerPort: 443,
                    hostPort: 443,
                },
            ],
            logConfiguration: {
                logDriver = "awslogs",
                options = {
                    "awslogs-group" = "${aws_cloudwatch_log_group.log-group.id}",
                    "awslogs-region" = "us-east-1",
                    "awslogs-stream-prefix" = "gh-${var.service}-${var.env}",
                },
            }
            environment: var.env_vars
        }
    ])
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

resource "aws_ecs_service" "gh_service" {
    name            = "gh-${var.service}-service-${var.env}"
    cluster         = aws_ecs_cluster.gh_cluster.id
    task_definition = "${aws_ecs_task_definition.gh_task_definition.arn}"
    launch_type     = "FARGATE"
    desired_count   = 1
    deployment_minimum_healthy_percent = 0
    force_new_deployment = true
    network_configuration {
        subnets = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
        assign_public_ip = true
        security_groups  = [aws_security_group.service_security_group.id]
    }
}

resource "aws_ecs_cluster" "gh_cluster" {
    name = "gh-cluster-${var.env}"
}

resource "aws_cloudwatch_log_group" "log-group" {
    name = "gh-${var.service}-logs-${var.env}"

    tags = {
        Application = "gh-${var.service}-${var.env}"
        Environment = var.env
    }
}

resource "aws_security_group" "service_security_group" {
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