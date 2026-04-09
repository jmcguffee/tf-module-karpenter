resource "aws_iam_policy" "node_lifecycle" {
  name        = "${var.cluster_name}-karpenter-node-lifecycle"
  description = "Karpenter node lifecycle management policy for ${var.cluster_name}"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowScopedEC2InstanceActionsWithTags"
        Effect = "Allow"
        Action = [
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:RunInstances",
        ]
        Resource = [
          "arn:aws:ec2:*:*:fleet/*",
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*:*:launch-template/*",
        ]
        Condition = {
          StringEquals = {
            "aws:RequestTag/karpenter.sh/discovery"                    = var.cluster_name
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        }
      },
      {
        Sid    = "AllowEC2RunInstancesSupportingResources"
        Effect = "Allow"
        Action = ["ec2:RunInstances"]
        Resource = [
          "arn:aws:ec2:*:*:image/*",
          "arn:aws:ec2:*:*:key-pair/*",
          "arn:aws:ec2:*:*:network-interface/*",
          "arn:aws:ec2:*:*:security-group/*",
          "arn:aws:ec2:*:*:snapshot/*",
          "arn:aws:ec2:*:*:subnet/*",
          "arn:aws:ec2:*:*:volume/*",
        ]
      },
      {
        Sid    = "AllowScopedDeletion"
        Effect = "Allow"
        Action = [
          "ec2:DeleteLaunchTemplate",
          "ec2:TerminateInstances",
        ]
        Resource = [
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*:*:launch-template/*",
        ]
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/karpenter.sh/discovery" = var.cluster_name
          }
        }
      },
      {
        Sid    = "AllowTaggingOnCreate"
        Effect = "Allow"
        Action = ["ec2:CreateTags"]
        Resource = [
          "arn:aws:ec2:*:*:fleet/*",
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*:*:launch-template/*",
          "arn:aws:ec2:*:*:network-interface/*",
          "arn:aws:ec2:*:*:volume/*",
        ]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = ["CreateFleet", "CreateLaunchTemplate", "RunInstances"]
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_lifecycle" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.node_lifecycle.arn
}
