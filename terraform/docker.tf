# https://hands-on.cloud/terraform-docker-lambda-example/



locals {
 ecr_repository_name = "${var.prefix}-${var.stage}-codm"
}

resource aws_ecr_repository repo {
    name = local.ecr_repository_name
}

resource null_resource ecr_image {
 triggers = {
   docker_file = md5(file("${path.root}/Dockerfile"))
 }

provisioner "local-exec" {
   command = <<EOF
           aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin "https://${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
           cd ${path.root}
           docker build --platform linux/amd64 -t ${aws_ecr_repository.repo.repository_url}:${var.docker_tag} .
           docker push ${aws_ecr_repository.repo.repository_url}:${var.docker_tag} -q
       EOF
 }
}

data aws_ecr_image batch_ecr_image {
 depends_on = [
   null_resource.ecr_image
 ]
 repository_name = local.ecr_repository_name
 image_tag       = var.docker_tag
}

