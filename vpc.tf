module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  # version = "3.14.3"

  name = "prod-eks-cluster-vpc-${local.environment}"
  cidr = "10.0.0.0/16"

  azs             = ["${data.aws_region.current.name}a", "${data.aws_region.current.name}b"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}": "owned"
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}": "owned"
    "kubernetes.io/role/internal-elb" = "1"
  }

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

 tags = {
   Creator = local.issuer
   RequestedBy = local.issuer
 }
}
