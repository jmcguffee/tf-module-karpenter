mock_provider "aws" {
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-policy"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }
  mock_resource "aws_iam_instance_profile" {
    defaults = {
      arn = "arn:aws:iam::123456789012:instance-profile/mock-instance-profile"
    }
  }
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:123456789012:test-cluster-karpenter"
      id  = "https://sqs.us-east-1.amazonaws.com/123456789012/test-cluster-karpenter"
    }
  }
  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
}

variables {
  cluster_name           = "test-cluster"
  cluster_endpoint       = "https://test.eks.amazonaws.com"
  oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  oidc_provider_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
}

run "controller_role_naming_convention" {
  command = apply

  assert {
    condition     = aws_iam_role.karpenter_controller.name == "test-cluster-karpenter-controller"
    error_message = "Controller role name must follow the <cluster_name>-karpenter-controller convention"
  }
}

run "controller_trust_policy_is_valid_json" {
  command = apply

  assert {
    condition     = can(jsondecode(aws_iam_role.karpenter_controller.assume_role_policy))
    error_message = "Controller trust policy must be valid JSON"
  }
}

run "controller_trust_policy_scoped_to_service_account" {
  command = apply

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
  command = apply

  assert {
    condition     = aws_iam_role.karpenter_node.name == "test-cluster-karpenter-node"
    error_message = "Node role name must follow the <cluster_name>-karpenter-node convention"
  }
}

run "instance_profile_matches_node_role_name" {
  command = apply

  assert {
    condition     = aws_iam_instance_profile.karpenter_node.name == "test-cluster-karpenter-node"
    error_message = "Instance profile name must match the node role name"
  }
}

run "node_lifecycle_policy_naming" {
  command = apply

  assert {
    condition     = aws_iam_policy.node_lifecycle.name == "test-cluster-karpenter-node-lifecycle"
    error_message = "Node lifecycle policy must follow the naming convention"
  }
}

run "node_lifecycle_provisioning_requires_region_condition" {
  command = apply

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.node_lifecycle.policy).Statement :
      try(s.Sid == "AllowScopedEC2InstanceActionsWithTags" &&
        s.Condition.StringEquals["aws:RequestedRegion"] == "us-east-1", false)
    ])
    error_message = "Provisioning actions must be gated by aws:RequestedRegion to prevent cross-region operations"
  }
}

run "node_lifecycle_scopes_provisioning_to_cluster_discovery_tag" {
  command = apply

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.node_lifecycle.policy).Statement :
      try(s.Condition.StringEquals["aws:RequestTag/karpenter.sh/discovery"] == "test-cluster", false)
    ])
    error_message = "Provisioning actions must require the karpenter.sh/discovery tag equal to the cluster name"
  }
}

run "node_lifecycle_scopes_termination_to_resource_tag_and_region" {
  command = apply

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.node_lifecycle.policy).Statement :
      try(s.Sid == "AllowScopedDeletion" &&
        s.Condition.StringEquals["ec2:ResourceTag/karpenter.sh/discovery"] == "test-cluster" &&
        s.Condition.StringEquals["aws:RequestedRegion"] == "us-east-1", false)
    ])
    error_message = "Termination must require both the cluster ResourceTag and aws:RequestedRegion"
  }
}

run "node_lifecycle_network_resources_require_cluster_tag" {
  command = apply

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.node_lifecycle.policy).Statement :
      try(s.Sid == "AllowRunInstancesOnClusterTaggedNetworkResources" &&
        s.Condition.StringEquals["ec2:ResourceTag/karpenter.sh/discovery"] == "test-cluster", false)
    ])
    error_message = "Subnets and security groups must require the karpenter.sh/discovery ResourceTag to prevent cross-cluster network access"
  }
}

run "node_lifecycle_resources_pinned_to_account_and_region" {
  command = apply

  assert {
    condition = alltrue([
      for r in jsondecode(aws_iam_policy.node_lifecycle.policy).Statement[0].Resource :
      can(regex("arn:aws:ec2:us-east-1:123456789012:", r))
    ])
    error_message = "Provisioning resource ARNs must be pinned to the specific account and region, not wildcarded"
  }
}

run "passrole_policy_naming" {
  command = apply

  assert {
    condition     = aws_iam_policy.passrole.name == "test-cluster-karpenter-passrole"
    error_message = "PassRole policy must follow the naming convention"
  }
}

run "passrole_conditioned_on_ec2_service" {
  command = apply

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.passrole.policy).Statement :
      try(contains(tolist(s.Condition.StringEquals["iam:PassedToService"]), "ec2.amazonaws.com"), false)
    ])
    error_message = "PassRole must be conditioned on iam:PassedToService = ec2.amazonaws.com"
  }
}

run "interruption_policy_scoped_to_queue_arn" {
  command = apply

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.interruption.policy).Statement :
      contains(tolist(s.Resource), aws_sqs_queue.interruption.arn)
    ])
    error_message = "Interruption policy must be scoped to the internally created queue ARN, not a wildcard"
  }
}

run "resource_discovery_eks_pinned_to_account_and_region" {
  command = apply

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.resource_discovery.policy).Statement :
      try(s.Sid == "AllowEKSClusterAccess" &&
        contains(tolist(s.Resource),
          "arn:aws:eks:us-east-1:123456789012:cluster/test-cluster"
        ), false)
    ])
    error_message = "EKS DescribeCluster must be pinned to the specific account, region, and cluster — not wildcarded"
  }
}

run "resource_discovery_ec2_describe_has_region_condition" {
  command = apply

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.resource_discovery.policy).Statement :
      try(s.Sid == "AllowEC2ResourceDiscovery" &&
        s.Condition.StringEquals["aws:RequestedRegion"] == "us-east-1", false)
    ])
    error_message = "EC2 Describe actions must include aws:RequestedRegion to prevent cross-region enumeration"
  }
}
