output "vpc" {
    value = module.vpc.vpc_id
}

output "vpc_public_subnets" {
    value = module.vpc.public_subnets
}

output "vpc_private_subnets" {
    value = module.vpc.private_subnets
}

output "vpc_intra_subnets" {
    value = module.vpc.intra_subnets
}