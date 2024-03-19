// ===============================
// VPC Variables
// ===============================

variable "vpc_name" {
    type        = string
    description = "Name of the VPC"
    nullable    = false
}

variable "vpc_cidr_block" {
    type        = string
    description = "CIDR Block of the created VPC"
    default     = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
    type        = map
    description = "CIDR Block of the created VPC's Public Subnets"
    default     = {
        "us-east-1a" = {
            cidr = "10.0.0.0/18"
        },
        "us-east-1b" = {
            cidr = "10.0.64.0/18"
        }
    }
}

variable "vpc_private_subnets" {
    type        = map
    description = "CIDR Block of the created VPC's Private Subnets"
    default     = {
        "us-east-1a" = {
            cidr = "10.0.128.0/18"
        },
        "us-east-1b" = {
            cidr = "10.0.192.0/18"
        }
    }
}

// ===============================
// Cluster Variables
// ===============================

variable "cluster_name" {
    type        = string
    description = "Name of the cluster"
    nullable    = false
}

variable "cluster_version" {
    type        = string
    description = "Version of the cluster"
    default     = "1.29"
}

variable "enable_public_access" {
    type        = bool
    description = "Should the cluster's endpoint be publically accessible"
    default     = true
}

variable "instance_types" {
    type        = list(string)
    description = "List of instance types available in the cluster"
    default     = ["r6g.xlarge"]
}

variable "node_grous" {
    type        = map(string)
    description = "A map of node group definitions to attach to the cluster"
    default     = {}
    // Sample Entry
    //
}

variable "access_entries" {
    type        = map(string)
    description = "A map of access entries definig cluster access"
    default     = {}
    // Sample Entry
    //
}