data "aws_availability_zones" "available" {}

locals {
    name     = var.vpc_name
    vpc_cidr = var.vpc_cidr_block
    azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "~> 5.0"

    name = local.name
    cidr = local.vpc_cidr

    azs             = local.azs
    private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
    public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
    intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

    enable_nat_gateway     = true
    single_nat_gateway     = true
    create_egress_only_igw = true

    public_subnet_tags = {
        "kubernetes.io/role/elb" = 1
    }

    private_subnet_tags = {
        "kubernetes.io/role/internal-elb" = 1
    }
}