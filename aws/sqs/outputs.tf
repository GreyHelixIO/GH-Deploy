output "gh_service_queue_arn" {
    value = aws_sqs_queue.gh_service_queue.arn
}

output "gh_service_queue_url" {
    value = aws_sqs_queue.gh_service_queue.url
}