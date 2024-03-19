variable "cluster_name" {
    type        = string
    description = "Name of the cluster"
    nullable    = false
}

variable "cluster_version" {
    type        = string
    description = "Version of the cluster"
    nullable    = false
}

variable "instance_types" {
    type        = list(string)
    description = "List of instance types available in the cluster"
    nullable    = false
}

variable "node_groups" {
    type        = map(string)
    description = "A map of node group definitions to attach to the cluster"
    nullable    = false
}

variable "access_entries" {
    type        = map(string)
    description = "A map of access entries definig cluster access"
    nullable    = false
}

variable "enable_public_access" {
    type        = string
    description = "Should the cluster's endpoint be publically accessible"
    nullable    = false
}

variable "vpc" {
    type        = string
    description = "AWS VPC Object"
    nullable    = false
}

variable "private_subnets" {
    type        = list(string)
    description = "AWS Private Subnet Objects"
    nullable    = false
}