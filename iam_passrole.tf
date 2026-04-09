resource "aws_iam_policy" "passrole" {
  name        = "${var.cluster_name}-karpenter-passrole"
  description = "Karpenter PassRole policy scoped to node IAM role in ${var.cluster_name}"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowPassRoleToNodeRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [aws_iam_role.karpenter_node.arn]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = ["ec2.amazonaws.com"]
          }
        }
      },
      {
        Sid      = "AllowGetInstanceProfile"
        Effect   = "Allow"
        Action   = ["iam:GetInstanceProfile"]
        Resource = [aws_iam_instance_profile.karpenter_node.arn]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "passrole" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.passrole.arn
}
