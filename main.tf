module "resources" {
  source = "./terraform"

  prefix = var.prefix
  stage  = var.stage

}

variable "prefix" {
  type = string
}

variable "stage" {
  type = string
}


output "batchJobDefinitionArn" {
  description = "Definition of batch job"
  value       = module.resources.batchJobDefinition
}

output "batchJobQueueName" {
  description = "Batch Job queue"
  value       = module.resources.batchJobQueueName
}

output "batchComputeEnvArn" {
  description = "ARN of batch compute environment"
  value       = module.resources.batchComputeEnvArn
}

output "ecsClusterArn" {
  description = "ECS cluster created by Batch compute environment"
  value       = module.resources.ecsClusterArn
}
output "snsTopic" {
  description = "SNS Topic that subscribes to changes in Batch Job status"
  value       = module.resources.snsTopic
}


output "bucket" {
    description = "CODM activated bucket"
    value = module.resources.bucket
}

