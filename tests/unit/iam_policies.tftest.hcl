mock_provider "aws" {}

variables {
  cluster_name           = "test-cluster"
  cluster_endpoint       = "https://test.eks.amazonaws.com"
  oidc_provider_arn      = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  oidc_provider_url      = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  interruption_queue_arn = "arn:aws:sqs:us-east-1:123456789012:test-cluster-karpenter-interruption"
}

run "controller_role_naming_convention" {
  command = plan

  assert {
    condition     = aws_iam_role.karpenter_controller.name == "test-cluster-karpenter-controller"
    error_message = "Controller role name must follow the <cluster_name>-karpenter-controller convention"
  }
}

run "controller_trust_policy_is_valid_json" {
  command = plan

  assert {
    condition     = can(jsondecode(aws_iam_role.karpenter_controller.assume_role_policy))
    error_message = "Controller trust policy must be valid JSON"
  }
}

run "controller_trust_policy_scoped_to_service_account" {
  command = plan

  variables {
    namespace            = "karpenter"
    service_account_name = "karpenter"
  }

  assert {
    condition = contains(
      values(jsondecode(aws_iam_role.karpenter_controller.assume_role_policy).Statement[0].Condition.StringEquals),
      "system:serviceaccount:karpenter:karpenter"
    )
    error_message = "Controller trust policy must be scoped to the specific Kubernetes service account"
  }
}

run "node_role_naming_convention" {
  command = plan

  assert {
    condition     = aws_iam_role.karpenter_node.name == "test-cluster-karpenter-node"
    error_message = "Node role name must follow the <cluster_name>-karpenter-node convention"
  }
}

run "instance_profile_matches_node_role_name" {
  command = plan

  assert {
    condition     = aws_iam_instance_profile.karpenter_node.name == "test-cluster-karpenter-node"
    error_message = "Instance profile name must match the node role name"
  }
}

run "node_lifecycle_policy_naming" {
  command = plan

  assert {
    condition     = aws_iam_policy.node_lifecycle.name == "test-cluster-karpenter-node-lifecycle"
    error_message = "Node lifecycle policy must follow the naming convention"
  }
}

run "node_lifecycle_scopes_provisioning_to_cluster_discovery_tag" {
  command = plan

  assert {
    condition = anytrue([
      for s in jsondecode(data.aws_iam_policy_document.node_lifecycle.json).Statement :
      can(s.Condition.StringEquals["aws:RequestTag/karpenter.sh/discovery"])
    ])
    error_message = "Node lifecycle policy must scope provisioning actions to karpenter.sh/discovery tag"
  }
}

run "node_lifecycle_scopes_termination_to_resource_tag" {
  command = plan

  assert {
    condition = anytrue([
      for s in jsondecode(data.aws_iam_policy_document.node_lifecycle.json).Statement :
      can(s.Condition.StringEquals["ec2:ResourceTag/karpenter.sh/discovery"])
    ])
    error_message = "Termination actions must use ec2:ResourceTag (existing resource), not aws:RequestTag"
  }
}

run "passrole_policy_naming" {
  command = plan

  assert {
    condition     = aws_iam_policy.passrole.name == "test-cluster-karpenter-passrole"
    error_message = "PassRole policy must follow the naming convention"
  }
}

run "passrole_conditioned_on_ec2_service" {
  command = plan

  assert {
    condition = anytrue([
      for s in jsondecode(data.aws_iam_policy_document.passrole.json).Statement :
      try(contains(s.Condition.StringEquals["iam:PassedToService"], "ec2.amazonaws.com"), false)
    ])
    error_message = "PassRole must be conditioned on iam:PassedToService = ec2.amazonaws.com"
  }
}

run "interruption_policy_scoped_to_queue_arn" {
  command = plan

  assert {
    condition = anytrue([
      for s in jsondecode(data.aws_iam_policy_document.interruption.json).Statement :
      contains(tolist(s.Resource), "arn:aws:sqs:us-east-1:123456789012:test-cluster-karpenter-interruption")
    ])
    error_message = "Interruption policy must be scoped to the specific queue ARN, not wildcard"
  }
}
