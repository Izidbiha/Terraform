################################################################################
# General
################################################################################
variable "create" {
  default = false
}
variable "create_cluster_security_group" {
  default = true
}
variable "create_iam_role" {
  default = true
}
variable "grafana_admin_password" {
}
variable "domain" {
}
variable "txt_id" {
}
variable "acm_cerificate" {
}
variable "argocdServerAdminPassword" {
}

# users (usernames) who will have access to the cluster
variable "auth_users" {
  type = list(string)
}
####################################### Keycloak Variables ##########################################
# All Variables must be encoded using base64
variable "keycloak_database_host" {
  type = string
}
variable "keycloak_database_port" {
  type    = number
  default = 5432
}
variable "keycloak_database_user" {
  type = string
}
variable "keycloak_database_name" {
  type = string
}
variable "keycloak_database_password" {
  type = string
}
variable "keycloak_admin_password" {
  type = string
}
variable "keycloak_tls_crt" {
  type        = string
  description = "Path to the keycloak TLS certificate file"
}
variable "keycloak_tls_key" {
  type        = string
  description = "Path to the keycloak TLS key file"
}



locals {
  create                    = var.create
  environment               = "prod"
  issuer                    = split("/", data.aws_iam_session_context.current.issuer_arn)[1]
  cluster_name              = "eks-cluster-prod"
  grafana_admin_password    = var.grafana_admin_password
  domain                    = var.domain
  txt_id                    = var.txt_id
  acm_cerificate            = var.acm_cerificate
  argocdServerAdminPassword = var.argocdServerAdminPassword
  auth_users                = var.auth_users
}




################################################################################
# IAM Role
################################################################################
locals {
  create_iam_role   = local.create && var.create_iam_role
  iam_role_name     = "ProdEksClusterRole-${local.environment}"
  policy_arn_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  cluster_encryption_policy_name = "${local.iam_role_name}-ClusterEncryption"
  account_id                     = data.aws_caller_identity.current.account_id


  dns_suffix = data.aws_partition.current.dns_suffix
}
