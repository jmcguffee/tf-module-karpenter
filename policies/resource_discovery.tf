data "aws_iam_policy_document" "resource_discovery" {
  statement {
    sid = "AllowEC2ResourceDiscovery"
    actions = [
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
    resources = ["*"]
  }

  statement {
    sid = "AllowEKSClusterAccess"
    actions = [
      "eks:DescribeCluster",
    ]
    resources = [
      "arn:aws:eks:*:*:cluster/${var.cluster_name}",
    ]
  }

  statement {
    sid = "AllowSSMParameterAccess"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      "arn:aws:ssm:*::parameter/aws/service/bottlerocket/*",
      "arn:aws:ssm:*::parameter/aws/service/eks/optimized-ami/*",
    ]
  }

  statement {
    sid = "AllowPricingAccess"
    actions = [
      "pricing:GetProducts",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "resource_discovery" {
  name        = "${var.cluster_name}-karpenter-resource-discovery"
  description = "Karpenter resource discovery policy for ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.resource_discovery.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "resource_discovery" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.resource_discovery.arn
}
