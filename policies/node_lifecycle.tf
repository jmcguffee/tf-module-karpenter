data "aws_iam_policy_document" "node_lifecycle" {
  statement {
    sid = "AllowEC2NodeManagement"
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:DeleteLaunchTemplate",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [data.aws_region.current.name]
    }
  }

  statement {
    sid = "AllowEC2DescribeForNodeLifecycle"
    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSpotPriceHistory",
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowTaggingForKarpenterResources"
    actions = [
      "ec2:CreateTags",
    ]
    resources = [
      "arn:aws:ec2:*:*:fleet/*",
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:launch-template/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [data.aws_region.current.name]
    }
  }
}

resource "aws_iam_policy" "node_lifecycle" {
  name        = "${var.cluster_name}-karpenter-node-lifecycle"
  description = "Karpenter node lifecycle management policy for ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.node_lifecycle.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "node_lifecycle" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.node_lifecycle.arn
}
