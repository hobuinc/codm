variable "prefix" {
    type = string
}

variable "stage" {
    type = string
    default = "dev"
}

variable "docker_tag" {
    type = string
    default = "latest"
}

variable "function_timeout" {
    type = number
    default = 300
}

output "batchJobQueueName" {
    description = "Batch Job queue"
    value = aws_batch_job_queue.batch-job-queue.name
}

output "batchJobDefinition" {
  description = "Definition of batch job"
  value       = aws_batch_job_definition.batch-job-definition.arn
}

output "batchComputeEnvArn" {
  description = "ARN of batch compute environment"
  value       = aws_batch_compute_environment.batch-compute-environment.arn
}

output "batchInstanceProfileArn" {
  description = "ARN of batch instance profile"
  value       = aws_iam_instance_profile.batch-instance-profile.arn
}

output "ecsClusterArn" {
  description = "ECS cluster created by Batch compute environment"
  value       = aws_batch_compute_environment.batch-compute-environment.ecs_cluster_arn
}


output "bucket" {
    description = "CODM activated bucket"
    value = aws_s3_bucket.storage.id
}
output "snsTopic" {
    description = "SNS Topic that subscribes to changes in Batch Job status"
    value = aws_sns_topic.codm-notifications-sns.arn
}
output "docker_image" {
    description = "Active ECR Image"
    value = "${aws_ecr_repository.repo.repository_url}:${var.docker_tag}"
}
