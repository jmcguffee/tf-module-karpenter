resource "aws_iam_policy" "node_lifecycle" {
  name        = "${var.cluster_name}-karpenter-node-lifecycle"
  description = "Karpenter node lifecycle management policy for ${var.cluster_name}"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Karpenter can only create resources that are tagged for THIS cluster
      # in THIS region. Dual-tag requirement prevents cross-cluster provisioning.
      {
        Sid    = "AllowScopedEC2InstanceActionsWithTags"
        Effect = "Allow"
        Action = [
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:RunInstances",
        ]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:fleet/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:launch-template/*",
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion"                                        = data.aws_region.current.region
            "aws:RequestTag/karpenter.sh/discovery"                      = var.cluster_name
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"   = "owned"
          }
        }
      },

      # Subnets and security groups must be tagged for THIS cluster.
      # Karpenter requires karpenter.sh/discovery on both — this prevents
      # Karpenter from launching into subnets or using SGs owned by other clusters.
      {
        Sid    = "AllowRunInstancesOnClusterTaggedNetworkResources"
        Effect = "Allow"
        Action = ["ec2:RunInstances"]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:security-group/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:subnet/*",
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion"                      = data.aws_region.current.region
            "ec2:ResourceTag/karpenter.sh/discovery"   = var.cluster_name
          }
        }
      },

      # AMIs, volumes, snapshots, key-pairs, and NICs cannot carry cluster
      # ownership tags. Scope is limited to this region only.
      {
        Sid    = "AllowRunInstancesOnUntaggableSupportingResources"
        Effect = "Allow"
        Action = ["ec2:RunInstances"]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.region}::image/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:key-pair/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
          "arn:aws:ec2:${data.aws_region.current.region}::snapshot/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:volume/*",
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.region
          }
        }
      },

      # Termination and template deletion are scoped to resources already tagged
      # for THIS cluster. ec2:ResourceTag (not aws:RequestTag) validates the tag
      # on the existing resource, preventing deletion of other clusters' nodes.
      {
        Sid    = "AllowScopedDeletion"
        Effect = "Allow"
        Action = [
          "ec2:DeleteLaunchTemplate",
          "ec2:TerminateInstances",
        ]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:launch-template/*",
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion"                      = data.aws_region.current.region
            "ec2:ResourceTag/karpenter.sh/discovery"   = var.cluster_name
          }
        }
      },

      # CreateTags is restricted to resources being created in the same API call
      # (ec2:CreateAction). This prevents using this permission to retroactively
      # tag arbitrary resources, and is further pinned to this region.
      {
        Sid    = "AllowTaggingOnCreate"
        Effect = "Allow"
        Action = ["ec2:CreateTags"]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:fleet/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:launch-template/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:volume/*",
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.region
            "ec2:CreateAction"    = ["CreateFleet", "CreateLaunchTemplate", "RunInstances"]
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
