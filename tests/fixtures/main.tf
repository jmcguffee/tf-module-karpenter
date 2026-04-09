terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

module "karpenter" {
  source = "../../"

  cluster_name      = "fixture-test-cluster"
  cluster_endpoint  = "https://EXAMPLEENDPOINT.gr7.us-east-1.eks.amazonaws.com"
  oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLEID"
  oidc_provider_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLEID"

  namespace            = "karpenter"
  service_account_name = "karpenter"

  enable_interruption_handling    = true
  enable_kms                      = true
  kms_key_deletion_window_in_days = 7
  queue_message_retention_seconds = 300

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
    Module      = "karpenter"
  }
}

output "controller_role_arn" {
  value = module.karpenter.controller_role_arn
}

output "node_role_arn" {
  value = module.karpenter.node_role_arn
}

output "queue_url" {
  value = module.karpenter.queue_url
}
