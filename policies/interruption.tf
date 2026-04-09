data "aws_iam_policy_document" "interruption" {
  count = var.enable_interruption_handling ? 1 : 0

  statement {
    sid = "AllowSQSInterruptionHandling"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
    ]
    resources = [
      aws_sqs_queue.karpenter_interruption[0].arn,
    ]
  }
}

resource "aws_iam_policy" "interruption" {
  count = var.enable_interruption_handling ? 1 : 0

  name        = "${var.cluster_name}-karpenter-interruption"
  description = "Karpenter interruption handling policy for ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.interruption[0].json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "interruption" {
  count = var.enable_interruption_handling ? 1 : 0

  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.interruption[0].arn
}
