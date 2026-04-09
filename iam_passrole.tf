data "aws_iam_policy_document" "passrole" {
  statement {
    sid = "AllowPassRoleToNodeRole"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.karpenter_node.arn,
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  statement {
    sid = "AllowGetInstanceProfile"
    actions = [
      "iam:GetInstanceProfile",
    ]
    resources = [
      aws_iam_instance_profile.karpenter_node.arn,
    ]
  }
}

resource "aws_iam_policy" "passrole" {
  name        = "${var.cluster_name}-karpenter-passrole"
  description = "Karpenter PassRole policy scoped to node IAM role in ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.passrole.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "passrole" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.passrole.arn
}
