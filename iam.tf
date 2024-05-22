module "allow-access-to-prod-eks-cluster-policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.20.0"

  name          = "AllowAccessToProdEksClusterPolicy-${local.environment}"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
  tags = {
    Creator = local.issuer
    RequestedBy = local.issuer
  }
}

module "prod_eks_cluster_access_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.20.0"

  role_name         = "ProdEksClusterAccessRole-${local.environment}"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow-access-to-prod-eks-cluster-policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
}

module "prod_eks_cluster_iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.20.0"

  name                          = "prod-eks-cluster-user-${local.environment}"
  create_iam_access_key         = false
  create_iam_user_login_profile = false

  force_destroy = true

  tags = {
    Creator = local.issuer
    RequestedBy = local.issuer
  }
}

module "prod_eks_cluster_access_role_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.20.0"

  name          = "allowAssumeProdEksClusterAccessPolicy-${local.environment}"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.prod_eks_cluster_access_role.iam_role_arn
      },
    ]
  })
  tags = {
    Creator = local.issuer
    RequestedBy = local.issuer
  }
}

module "prod_eks_cluster_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.20.0"

  name                              = "prod-eks-cluster-group-${local.environment}"
  attach_iam_self_management_policy = false
  create_group                      = true
  group_users                       = [module.prod_eks_cluster_iam_user.iam_user_name]
  custom_group_policy_arns          = [module.prod_eks_cluster_access_role_policy.arn]
  tags = {
    Creator = local.issuer
    RequestedBy = local.issuer
  }
}

module "prod_eks_cluster_kms_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.20.0"

  name          = "allowKSMEncryptionToProdEksClusterEBSVolumePolicy-${local.environment}"
  create_policy = true

  policy = <<EOF
{
    "Version":"2012-10-17",
    "Statement": [
      {
  "Effect":"Allow",
  "Action": [
      "kms:Decrypt",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
  ],
  "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
    ]
} 
EOF


  tags = {
    Creator = local.issuer
    RequestedBy = local.issuer
    Name    = "prodEksClusterEbsVolume-${local.environment}"
  }
}

module "aws_ebs_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = "prodEksCluterEBSRole-${local.environment}"

  attach_ebs_csi_policy = true

  role_policy_arns = {
    policy = module.prod_eks_cluster_kms_policy.arn
  }
  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}
