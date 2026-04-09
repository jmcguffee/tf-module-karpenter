data "aws_iam_policy_document" "node_lifecycle" {
  statement {
    sid = "AllowScopedEC2InstanceActionsWithTags"
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:RunInstances",
    ]
    resources = [
      "arn:aws:ec2:*:*:fleet/*",
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:launch-template/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/karpenter.sh/discovery"
      values   = [var.cluster_name]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }
  }

  statement {
    sid = "AllowEC2RunInstancesSupportingResources"
    actions = [
      "ec2:RunInstances",
    ]
    resources = [
      "arn:aws:ec2:*:*:image/*",
      "arn:aws:ec2:*:*:key-pair/*",
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:snapshot/*",
      "arn:aws:ec2:*:*:subnet/*",
      "arn:aws:ec2:*:*:volume/*",
    ]
  }

  statement {
    sid = "AllowScopedDeletion"
    actions = [
      "ec2:DeleteLaunchTemplate",
      "ec2:TerminateInstances",
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:launch-template/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/karpenter.sh/discovery"
      values   = [var.cluster_name]
    }
  }

  statement {
    sid = "AllowTaggingOnCreate"
    actions = [
      "ec2:CreateTags",
    ]
    resources = [
      "arn:aws:ec2:*:*:fleet/*",
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:launch-template/*",
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:volume/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = [
        "CreateFleet",
        "CreateLaunchTemplate",
        "RunInstances",
      ]
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
