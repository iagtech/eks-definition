resource "aws_vpc" "vpc" {
    cidr_block           = var.vpc_cidr_block
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name = var.vpc_name
    }
}

resource "aws_subnet" "public_subnet" {
    for_each = var.vpc_public_subnets

    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = each.value.cidr
    availability_zone       = each.key
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.vpc_name}-public-${each.key}"
        "kubernetes.io/role/elb" = 1
    }
}

resource "aws_subnet" "private_subnet" {
    for_each = var.vpc_private_subnets

    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = each.value.cidr
    availability_zone       = each.key
    map_public_ip_on_launch = false

    tags = {
        Name = "${var.vpc_name}-private-${each.key}"
        "kubernetes.io/role/internal-elb" = 1
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "${var.vpc_name}-gw"
    }
}

resource "aws_eip" "nat_gw_eip" {
    for_each = var.vpc_public_subnets
}

resource "aws_nat_gateway" "nat_gw" {
    for_each = var.vpc_public_subnets

    allocation_id = aws_eip.nat_gw_eip[each.key].id
    subnet_id     = aws_subnet.public_subnet[each.key].id

    tags = {
        Name = "${var.vpc_name}-nat-gw-${each.key}"
    }
    
    depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table_association" "public" {
    for_each = var.vpc_public_subnets
    
    subnet_id      = aws_subnet.public_subnet[each.key].id
    route_table_id = aws_route_table.public.id
}

resource "aws_route" "public_internet_gateway" {
    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.gw.id

    timeouts {
        create = "5m"
    }
}

resource "aws_route_table" "private" {
    for_each = var.vpc_private_subnets 

    vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table_association" "private" {
    for_each = var.vpc_private_subnets

    subnet_id      = aws_subnet.private_subnet[each.key].id
    route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route" "private_internet_gateway" {
    for_each = var.vpc_private_subnets  

    route_table_id         = aws_route_table.private[each.key].id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gw[each.key].id

    timeouts {
        create = "5m"
    }
}