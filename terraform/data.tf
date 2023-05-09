data "aws_region" "current" {}

data "aws_availability_zones" "available" {
    state = "available"
}

data "aws_availability_zone" "available" {
  for_each = toset(data.aws_availability_zones.available.names)
  name     = each.value
}


data "aws_caller_identity" "current" {}


data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended"
}

