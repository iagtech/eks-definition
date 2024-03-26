module "vpc" {
    source = "./modules/vpc"

    vpc_name            = var.vpc_name
    vpc_cidr_block      = var.vpc_cidr_block
}

module "eks" {
    source = "./modules/eks"

    region                       = var.region
    partition                    = var.partition
    cluster_name                 = var.cluster_name
    cluster_version              = var.cluster_version
    cluster_enable_public_access = var.cluster_enable_public_access
    cluster_node_groups          = var.cluster_node_groups
    vpc                          = module.vpc.vpc
    vpc_private_subnets          = module.vpc.vpc_private_subnets
    vpc_public_subnets           = module.vpc.vpc_public_subnets
}