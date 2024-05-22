module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.29.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.27"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.aws_ebs_irsa_role.iam_role_arn
    }
  }

  enable_irsa = true

  eks_managed_node_group_defaults = {
    disk_size      = 8
    instance_types = ["t3.small"]
  }

  eks_managed_node_groups = {
    initialization_group = {

      desired_size = 1
      min_size     = 1
      max_size     = 1

      labels = {
        role = "initialization_group"
      }
      capacity_type = "ON_DEMAND"
    }

    // this node group will contains any pods that are used for cluster configuration purpose 
    configuration_purpose = {
      ami_type       = "AL2_ARM_64" // change AMI architecture to arm64
      instance_types = ["t4g.small"]
      desired_size   = 3
      min_size       = 3
      max_size       = 4
      labels = {
        "node.kubernetes.io/purpose" = "configuration_purpose"
      }
      taints = {
        configuration_purpose = {
          key    = "workload"
          value  = "configuration_purpose"
          effect = "NO_SCHEDULE"
        }
      }
      capacity_type = "ON_DEMAND"
    }

    general_workloads = {
      ami_type       = "AL2_ARM_64" // change AMI architecture to arm64
      instance_types = ["t4g.medium"]
      desired_size   = 4
      min_size       = 2
      max_size       = 7
      labels = {
        "node.kubernetes.io/purpose" = "general_workloads"
      }
      taints = {
        general_workloads = {
          key    = "workload"
          value  = "general_workloads"
          effect = "NO_SCHEDULE"
        }
      }
      capacity_type = "ON_DEMAND"
    }

  }

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = module.prod_eks_cluster_access_role.iam_role_arn
      username = module.prod_eks_cluster_access_role.iam_role_name
      groups   = ["system:masters"]
    },
  ]

  # give iam users access to cluster objects
  aws_auth_users = [for i, user in local.auth_users : {
    userarn  = "arn:aws:iam::${local.account_id}:user/${user}"
    username = "${user}"
    groups   = ["system:masters"]
  }]

  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
    ingress_allow_access_from_control_plane_to_nginx_ingress_controller = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of Nginx ingress controller"

    }

    ingress_allow_access_within_the_cluster = {
      type        = "ingress"
      protocol    = -1
      from_port   = -1
      to_port     = -1
      self        = true
      description = "Allow access within the cluster"

    }
    ingress_allow_access_within_the_cluster_egress = {
      type        = "egress"
      protocol    = -1
      from_port   = -1
      to_port     = -1
      self        = true
      description = "Allow access within the cluster"

    }

    ingress_allow_database_access = {
      type        = "ingress"
      protocol    = "tcp"
      from_port   = 5432
      to_port     = 5432
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow PostgreSQL access - ingress"
    }
    egress_allow_database_access = {
      type        = "egress"
      protocol    = "tcp"
      from_port   = 5432
      to_port     = 5432
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow PostgreSQL access - engress"

    }

    // Allow SMTP through port 587 for email communication

    ingress_allow_smtp_access = {
      type        = "ingress"
      protocol    = "tcp"
      from_port   = 587
      to_port     = 587
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow SMTP access - ingress"
    }
    egress_allow_smtp_access = {
      type        = "egress"
      protocol    = "tcp"
      from_port   = 587
      to_port     = 587
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow SMTP access - engress"

    }
    // Allow Keycloak Auth server URL communication through port 8180

    ingress_allow_keycloak_auth_server_url_communication = {
      type        = "ingress"
      protocol    = "tcp"
      from_port   = 8180
      to_port     = 8180
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow Keycloak Auth server URL communication - ingress"
    }
    egress_allow_keycloak_auth_server_url_communication = {
      type        = "egress"
      protocol    = "tcp"
      from_port   = 8180
      to_port     = 8180
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow Keycloak Auth server URL communication - engress"

    }

    

    ingress_allow_http_access = {
      type        = "ingress"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP access - ingress"

    }
    egress_allow_http_access = {
      type        = "egress"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP access - engress"

    }
  }


  # cluster_security_group_additional_rules = {
  #   ingress_allow_access_within_the_cluster = {
  #     type                       = "ingress"
  #     protocol                   = -1
  #     from_port                  = -1
  #     to_port                    = -1
  #     source_node_security_group = true
  #     description                = "Allow access within the cluster"

  #   }
  # }

  tags = {
    Creator     = local.issuer
    RequestedBy = local.issuer
  }
}

# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009
data "aws_eks_cluster" "default" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_id
}



provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    command     = "aws"
  }
}
