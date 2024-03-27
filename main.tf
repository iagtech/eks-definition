module "vpc" {
    source = "./modules/vpc"

    vpc_name            = var.vpc_name
    vpc_cidr_block      = var.vpc_cidr_block
}

module "eks" {
    source = "./modules/eks"

    cluster_name                 = var.cluster_name
    cluster_version              = var.cluster_version
    cluster_enable_public_access = var.cluster_enable_public_access
    cluster_node_groups          = var.cluster_node_groups
    cluster_admin_users          = var.cluster_admin_users
    cluster_readonly_users       = var.cluster_readonly_users
    vpc                          = module.vpc.vpc
    vpc_private_subnets          = module.vpc.vpc_private_subnets
    vpc_public_subnets           = module.vpc.vpc_public_subnets
    vpc_intra_subnets            = module.vpc.vpc_intra_subnets
}

resource "null_resource" "eks_access" {
    provisioner "local-exec" {
        command = "aws eks update-kubeconfig --name ${var.cluster_name} --role-arn ${module.eks.admin_arn}"
    }
}