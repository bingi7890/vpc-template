################
# Publiс routes
################
resource "aws_route_table" "public" {
  count = "${var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id = "${local.vpc_id}"

  tags = "${merge(map("Name", format("%s-${var.public_subnet_suffix}", var.name)), var.tags, var.public_route_table_tags)}"
}

resource "aws_route" "public_internet_gateway" {
  count = "${var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0}"

  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.this.id}"

  timeouts {
    create = "5m"
  }
}

#################
# Private routes
# There are so many routing tables as the largest amount of subnets of each type (really?)
#################
resource "aws_route_table" "private" {
  count = "${var.create_vpc && local.max_subnet_length > 0 ? local.nat_gateway_count : 0}"

  vpc_id = "${local.vpc_id}"

  tags = "${merge(map("Name", (var.single_nat_gateway ? "${var.name}-${var.private_subnet_suffix}" : format("%s-${var.private_subnet_suffix}-%s", var.name, element(var.azs, count.index)))), var.tags, var.private_route_table_tags)}"

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = ["propagating_vgws"]
  }
}

#################
# Database routes
#################
resource "aws_route_table" "database" {
  count = "${var.create_vpc && var.create_database_subnet_route_table && length(var.database_subnets) > 0 ? 1 : 0}"

  vpc_id = "${local.vpc_id}"

  tags = "${merge(var.tags, var.database_route_table_tags, map("Name", "${var.name}-${var.database_subnet_suffix}"))}"
}

resource "aws_route" "database_internet_gateway" {
  count = "${var.create_vpc && var.create_database_subnet_route_table && length(var.database_subnets) > 0 && var.create_database_internet_gateway_route && !var.create_database_nat_gateway_route ? 1 : 0}"

  route_table_id         = "${aws_route_table.database.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.this.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_nat_gateway" {
  count                  = "${var.create_vpc && var.create_database_subnet_route_table && length(var.database_subnets) > 0 && !var.create_database_internet_gateway_route && var.create_database_nat_gateway_route && var.enable_nat_gateway ? local.nat_gateway_count : 0}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.this.*.id, count.index)}"

  timeouts {
    create = "5m"
  }
}
