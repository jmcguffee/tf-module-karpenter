resource "aws_iam_policy" "resource_discovery" {
  name        = "${var.cluster_name}-karpenter-resource-discovery"
  description = "Karpenter resource discovery policy for ${var.cluster_name}"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EC2 Describe actions cannot be scoped by resource tag (AWS limitation).
      # Region condition prevents enumeration of other regions.
      {
        Sid    = "AllowEC2ResourceDiscovery"
        Effect = "Allow"
        Action = [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
        ]
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.region
          }
        }
      },

      # Pinned to the exact account, region, and cluster name — not just cluster name.
      # Prevents describing a same-named cluster in another account or region.
      {
        Sid    = "AllowEKSClusterAccess"
        Effect = "Allow"
        Action = ["eks:DescribeCluster"]
        Resource = [
          "arn:aws:eks:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}",
        ]
      },

      # AWS-managed parameters — no account in ARN by design (these live under ::).
      # Paths are already tightly scoped to known EKS/Bottlerocket AMI parameter namespaces.
      {
        Sid    = "AllowSSMParameterAccess"
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.region}::parameter/aws/service/bottlerocket/*",
          "arn:aws:ssm:${data.aws_region.current.region}::parameter/aws/service/eks/optimized-ami/*",
        ]
      },

      # Pricing uses a global endpoint — aws:RequestedRegion does not apply.
      # Read-only and does not expose cluster-specific data.
      {
        Sid      = "AllowPricingAccess"
        Effect   = "Allow"
        Action   = ["pricing:GetProducts"]
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "resource_discovery" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.resource_discovery.arn
}
