resource "aws_iam_policy" "interruption" {
  name        = "${var.cluster_name}-karpenter-interruption"
  description = "Karpenter interruption handling policy for ${var.cluster_name}"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSInterruptionHandling"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
        ]
        Resource = [var.interruption_queue_arn]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "interruption" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.interruption.arn
}
