data "aws_iam_policy_document" "interruption" {
  statement {
    sid = "AllowSQSInterruptionHandling"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
    ]
    resources = [
      var.interruption_queue_arn,
    ]
  }
}

resource "aws_iam_policy" "interruption" {
  name        = "${var.cluster_name}-karpenter-interruption"
  description = "Karpenter interruption handling policy for ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.interruption.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "interruption" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.interruption.arn
}
