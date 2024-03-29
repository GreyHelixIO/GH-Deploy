data "aws_iam_policy_document" "assume_role_policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
        type        = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
        }
    }
}

data "aws_ecs_service" "gh_service" {
    cluster_arn = aws_ecs_cluster.gh_cluster.arn
    service_name = aws_ecs_service.gh_service.name
}