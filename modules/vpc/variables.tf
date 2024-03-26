variable "vpc_name" {
    type        = string
    description = "Name of the VPC in which the EKS cluster will be created (i.e. qa, prod)"
    nullable    = false
}

variable "vpc_cidr_block" {
    type        = string
    description = "CIDR Block of the created VPC"
    nullable    = false
}