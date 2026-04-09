resource "aws_iam_policy" "resource_discovery" {
  name        = "${var.cluster_name}-karpenter-resource-discovery"
  description = "Karpenter resource discovery policy for ${var.cluster_name}"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
      },
      {
        Sid      = "AllowEKSClusterAccess"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = ["arn:aws:eks:*:*:cluster/${var.cluster_name}"]
      },
      {
        Sid    = "AllowSSMParameterAccess"
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          "arn:aws:ssm:*::parameter/aws/service/bottlerocket/*",
          "arn:aws:ssm:*::parameter/aws/service/eks/optimized-ami/*",
        ]
      },
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
