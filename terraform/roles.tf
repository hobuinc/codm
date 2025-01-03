resource "aws_iam_role" "batch-service-role" {
  name = "${var.prefix}-BatchServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service : "batch.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "batch-spot-fleet-role" {
  name = "${var.prefix}-BatchSpotFleetRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service : "spotfleet.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

}

resource "aws_iam_policy" "batch-spot-fleet-policy" {
    name = "${var.prefix}-LandrushBatchSpotFleetPolicy"

    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:DescribeImages",
                    "ec2:DescribeSubnets",
                    "ec2:RequestSpotInstances",
                    "ec2:TerminateInstances",
                    "ec2:DescribeInstanceStatus",
                    "ec2:CreateTags",
                    "ec2:RunInstances"
                ],
                "Resource": [
                    "*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": "iam:PassRole",
                "Condition": {
                    "StringEquals": {
                        "iam:PassedToService": [
                            "ec2.amazonaws.com",
                            "ec2.amazonaws.com.cn"
                        ]
                    }
                },
                "Resource": [
                    "*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
                ],
                "Resource": [
                    "arn:aws:elasticloadbalancing:*:*:loadbalancer/*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:RegisterTargets"
                ],
                "Resource": [
                    "arn:aws:elasticloadbalancing:*:*:*/*"
                ]
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "attach-spot-fleet-policy" {
  role       = aws_iam_role.batch-spot-fleet-role.name
  policy_arn = aws_iam_policy.batch-spot-fleet-policy.arn
}

resource "aws_iam_policy" "batch-service-policy" {
  name = "${var.prefix}-LandrushBatchServicePolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeImages",
          "ec2:DescribeImageAttribute",
          "ec2:DescribeSpotInstanceRequests",
          "ec2:DescribeSpotFleetInstances",
          "ec2:DescribeSpotFleetRequests",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeVpcClassicLink",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:CreateLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:RequestSpotFleet",
          "ec2:CancelSpotFleetRequests",
          "ec2:ModifySpotFleetRequest",
          "ec2:TerminateInstances",
          "ec2:RunInstances",
          "autoscaling:DescribeAccountLimits",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:CreateLaunchConfiguration",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DeleteLaunchConfiguration",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:SuspendProcesses",
          "autoscaling:PutNotificationConfiguration",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ecs:DescribeClusters",
          "ecs:DescribeContainerInstances",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListClusters",
          "ecs:ListContainerInstances",
          "ecs:ListTaskDefinitionFamilies",
          "ecs:ListTaskDefinitions",
          "ecs:ListTasks",
          "ecs:CreateCluster",
          "ecs:DeleteCluster",
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:RunTask",
          "ecs:StartTask",
          "ecs:StopTask",
          "ecs:UpdateContainerAgent",
          "ecs:DeregisterContainerInstance",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "iam:GetInstanceProfile",
          "iam:GetRole"
        ]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "spot.amazonaws.com",
              "spotfleet.amazonaws.com",
              "autoscaling.amazonaws.com",
              "ecs.amazonaws.com"
            ]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateTags"]
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "RunInstances"
          }
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "service-attach-1" {
  role       = aws_iam_role.batch-service-role.name
  policy_arn = aws_iam_policy.batch-service-policy.arn
}

####################

resource "aws_iam_role" "batch-job-role" {
  name = "${var.prefix}-${var.stage}-BatchJobRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_policy" "sqs-full-access" {
  name = "${var.prefix}-${var.stage}-SqsFullAccess"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:*"]
        Resource = ["*"]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "sqs-job-attach" {
  role       = aws_iam_role.batch-job-role.name
  policy_arn = aws_iam_policy.sqs-full-access.arn
}



resource "aws_iam_policy" "ecs-full-access" {
  name = "${var.prefix}-${var.stage}-EcsFullAccess"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeImages",
                "ec2:DescribeImageAttribute",
                "ec2:DescribeSpotInstanceRequests",
                "ec2:DescribeSpotFleetInstances",
                "ec2:DescribeSpotFleetRequests",
                "ec2:DescribeSpotPriceHistory",
                "ec2:DescribeVpcClassicLink",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:RequestSpotFleet",
                "autoscaling:DescribeAccountLimits",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeAutoScalingInstances",
                "eks:DescribeCluster",
                "ecs:DescribeClusters",
                "ecs:DescribeContainerInstances",
                "ecs:DescribeTaskDefinition",
                "ecs:DescribeTasks",
                "ecs:ListClusters",
                "ecs:ListContainerInstances",
                "ecs:ListTaskDefinitionFamilies",
                "ecs:ListTaskDefinitions",
                "ecs:ListTasks",
                "ecs:DeregisterTaskDefinition",
                "ecs:TagResource",
                "ecs:ListAccountSettings",
                "logs:DescribeLogGroups",
                "iam:GetInstanceProfile",
                "iam:GetRole"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:/aws/batch/job*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:/aws/batch/job*:log-stream:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:CreateOrUpdateTags"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/AWSBatchServiceTag": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": [
                "*"
            ],
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": [
                        "ec2.amazonaws.com",
                        "ec2.amazonaws.com.cn",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "spot.amazonaws.com",
                        "spotfleet.amazonaws.com",
                        "autoscaling.amazonaws.com",
                        "ecs.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateLaunchTemplate"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/AWSBatchServiceTag": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:TerminateInstances",
                "ec2:CancelSpotFleetRequests",
                "ec2:ModifySpotFleetRequest",
                "ec2:DeleteLaunchTemplate"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/AWSBatchServiceTag": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:CreateLaunchConfiguration",
                "autoscaling:DeleteLaunchConfiguration"
            ],
            "Resource": "arn:aws:autoscaling:*:*:launchConfiguration:*:launchConfigurationName/AWSBatch*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:CreateAutoScalingGroup",
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:DeleteAutoScalingGroup",
                "autoscaling:SuspendProcesses",
                "autoscaling:PutNotificationConfiguration",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/AWSBatch*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DeleteCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:RunTask",
                "ecs:StartTask",
                "ecs:StopTask"
            ],
            "Resource": "arn:aws:ecs:*:*:cluster/AWSBatch*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:RunTask",
                "ecs:StartTask",
                "ecs:StopTask"
            ],
            "Resource": "arn:aws:ecs:*:*:task-definition/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:StopTask"
            ],
            "Resource": "arn:aws:ecs:*:*:task/*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:CreateCluster",
                "ecs:RegisterTaskDefinition"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/AWSBatchServiceTag": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": [
                "arn:aws:ec2:*::image/*",
                "arn:aws:ec2:*::snapshot/*",
                "arn:aws:ec2:*:*:subnet/*",
                "arn:aws:ec2:*:*:network-interface/*",
                "arn:aws:ec2:*:*:security-group/*",
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:key-pair/*",
                "arn:aws:ec2:*:*:launch-template/*",
                "arn:aws:ec2:*:*:placement-group/*",
                "arn:aws:ec2:*:*:capacity-reservation/*",
                "arn:aws:ec2:*:*:elastic-gpu/*",
                "arn:aws:elastic-inference:*:*:elastic-inference-accelerator/*",
                "arn:aws:resource-groups:*:*:group/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/AWSBatchServiceTag": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": [
                "*"
            ],
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": [
                        "RunInstances",
                        "CreateLaunchTemplate",
                        "RequestSpotFleet"
                    ]
                }
            }
        }
    ]
})
}
resource "aws_iam_role_policy_attachment" "ecs-full-job-attach" {
  role       = aws_iam_role.batch-job-role.name
  policy_arn = aws_iam_policy.ecs-full-access.arn
}


resource "aws_iam_policy" "ecs-task-execution" {
  name = "${var.prefix}-${var.stage}-EcsTaskExecutionPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["*"]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs-task-job-attach" {
  role       = aws_iam_role.batch-job-role.name
  policy_arn = aws_iam_policy.ecs-task-execution.arn
}

####################


resource "aws_iam_policy" "operating-policy" {
  name = "${var.prefix}-LandrushEc2OperatingPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:*"]
        Resource = ["*"]
      },
    #   {
    #     Effect   = "Allow"
    #     Action   = ["elasticloadbalancing:*"]
    #     Resource = ["*"]
    #   },
      {
        Effect   = "Allow"
        Action   = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
        ]
        Resource = ["*"]
      },
      {
        Effect  = "Allow"
        Action  = [
            "s3:DeleteObject",
            "s3:GetObject",
            "s3:GetObjectTagging",
            "s3:ListBucket",
            "s3:ListBucketVersions",
            "s3:PutObject",
            "s3:PutObjectTagging",
        ],
        Resource = [ "${aws_s3_bucket.storage.arn}/*" ]
      },
      {
        Effect  = "Allow"
        Action  = [
            "s3:ListBucket",
            "s3:ListBucketVersions"
        ],
        Resource = [ aws_s3_bucket.storage.arn ]
      },
    #   {
    #     Effect   = "Allow"
    #     Action   = ["autoscaling:*"]
    #     Resource = ["*"]
    #   },
      {
        Effect    = "Allow"
        Action    = ["iam:CreateServiceLinkedRole"]
        Resource  = ["*"]
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "autoscaling.amazonaws.com",
              "ec2scheduled.amazonaws.com",
              "elasticloadbalancing.amazonaws.com",
              "spot.amazonaws.com",
              "spotfleet.amazonaws.com",
              "transitgateway.amazonaws.com"
            ]
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "operating-policy-attach" {
  role       = aws_iam_role.batch-instance-profile-role.name
  policy_arn = aws_iam_policy.operating-policy.arn
}


# resource "aws_iam_role_policy_attachment" "sqs-instance-attach" {
#   role       = aws_iam_role.batch-instance-profile-role.name
#   policy_arn = aws_iam_policy.sqs-full-access.arn
# }


resource "aws_iam_role_policy" "ecr-full-access" {
  name = "${var.prefix}-EcrFullAccess"
  role = aws_iam_role.batch-instance-profile-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:*",
          "cloudtrail:LookupEvents"
        ]
        Resource = ["*"]
      }
    ]
  })
}



//Instead of BatchServiceRole2 policy
resource "aws_iam_role_policy_attachment" "service-attach-2" {
  role       = aws_iam_role.batch-instance-profile-role.name
  policy_arn = aws_iam_policy.batch-service-policy.arn
}


resource "aws_iam_role_policy" "cloudwatch-logs-access" {
  name = "${var.prefix}-CloudWatchLogsAccess"
  role = aws_iam_role.batch-instance-profile-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = ["*"]
      }
    ]
  })
}


resource "aws_iam_role_policy" "ecs-full-access-instance" {
  name = "${var.prefix}-EcsFullAccess"
  role = aws_iam_role.batch-instance-profile-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "application-autoscaling:DeleteScalingPolicy",
          "application-autoscaling:DeregisterScalableTarget",
          "application-autoscaling:DescribeScalableTargets",
          "application-autoscaling:DescribeScalingActivities",
          "application-autoscaling:DescribeScalingPolicies",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:RegisterScalableTarget",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:CreateLaunchConfiguration",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DeleteLaunchConfiguration",
          "autoscaling:Describe*",
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStack*",
          "cloudformation:UpdateStack",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:PutMetricAlarm",
          "codedeploy:CreateApplication",
          "codedeploy:CreateDeployment",
          "codedeploy:CreateDeploymentGroup",
          "codedeploy:GetApplication",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:ListApplications",
          "codedeploy:ListDeploymentGroups",
          "codedeploy:ListDeployments",
          "codedeploy:StopDeployment",
          "codedeploy:GetDeploymentTarget",
          "codedeploy:ListDeploymentTargets",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetApplicationRevision",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:BatchGetApplicationRevisions",
          "codedeploy:BatchGetDeploymentGroups",
          "codedeploy:BatchGetDeployments",
          "codedeploy:BatchGetApplications",
          "codedeploy:ListApplicationRevisions",
          "codedeploy:ListDeploymentConfigs",
          "codedeploy:ContinueDeployment",
          "sns:ListTopics",
          "lambda:ListFunctions",
          "ec2:AssociateRouteTable",
          "ec2:AttachInternetGateway",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CancelSpotFleetRequests",
          "ec2:CreateInternetGateway",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateRoute",
          "ec2:CreateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSubnet",
          "ec2:CreateVpc",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteSubnet",
          "ec2:DeleteVpc",
          "ec2:Describe*",
          "ec2:DetachInternetGateway",
          "ec2:DisassociateRouteTable",
          "ec2:ModifySubnetAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:RunInstances",
          "ec2:RequestSpotFleet",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "ecs:*",
          "events:DescribeRule",
          "events:DeleteRule",
          "events:ListRuleNamesByTarget",
          "events:ListTargetsByRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfiles",
          "iam:ListRoles",
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:FilterLogEvents",
          "route53:GetHostedZone",
          "route53:ListHostedZonesByName",
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
          "route53:GetHealthCheck",
          "servicediscovery:CreatePrivateDnsNamespace",
          "servicediscovery:CreateService",
          "servicediscovery:GetNamespace",
          "servicediscovery:GetOperation",
          "servicediscovery:GetService",
          "servicediscovery:ListNamespaces",
          "servicediscovery:ListServices",
          "servicediscovery:UpdateService",
          "servicediscovery:DeleteService"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = ["arn:aws:ssm:*:*:parameter/aws/service/ecs*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteInternetGateway",
          "ec2:DeleteRoute",
          "ec2:DeleteRouteTable",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = ["*"]
        Condition = {
          StringLike = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = ["arn:aws:iam::*:role/ecsInstanceRole*"]
        Condition = {
          StringLike = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "ec2.amazonaws.com.cn"
            ]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = ["arn:aws:iam::*:role/ecsAutoscaleRole"]
        Condition = {
          StringLike = {
            "iam:PassedToService" = [
              "application-autoscaling.amazonaws.com",
              "application-autoscaling.amazonaws.com.cn"
            ]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["iam:CreateServiceLinkedRole"]
        Resource = ["*"]
        Condition = {
          StringLike = {
            "iam:AWSServiceName" = [
              "ecs.amazonaws.com",
              "spot.amazonaws.com",
              "spotfleet.amazonaws.com",
              "ecs.application-autoscaling.amazonaws.com",
              "autoscaling.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2-container-service-stuff" {
  name = "${var.prefix}-Ec2ContainerServiceStuff"
  role = aws_iam_role.batch-instance-profile-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateCluster",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:UpdateContainerInstancesState",
          "ecs:Submit*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ssm-readonly" {
  name = "${var.prefix}-SSMReadOnly"
  role = aws_iam_role.batch-instance-profile-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:Describe*",
          "ssm:Get*",
          "ssm:List*"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "batch-instance-profile" {
  name = "${var.prefix}-${var.stage}-BatchInstanceProfile"
  role = aws_iam_role.batch-instance-profile-role.name
}

resource "aws_iam_role" "batch-instance-profile-role" {
  name = "${var.prefix}-${var.stage}-BatchInstanceProfileRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "batchoperations.s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
