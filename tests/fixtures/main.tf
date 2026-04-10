terraform {
  required_version = ">= 1.7.0"
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

output "node_instance_profile_name" {
  value = module.karpenter.node_instance_profile_name
}
