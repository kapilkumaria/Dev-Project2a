# ===================================================================================================================
# Creating all 3 aws providers for 3 different regions us-east-1, eu-west-1 & eu-west-2 (Virginia, Ireland & London)
# ===================================================================================================================

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "london"
  region = "eu-west-2"
}


# ===================================================================================================================
# Creating all 3 VPC in 3 different regions us-east-1, eu-west-1 & eu-west-2 (Virginia, Ireland & London)
# ===================================================================================================================

resource "aws_vpc" "vpg" {
  cidr_block           = "172.${var.subnet_second_octet}.${var.subnet_third_octet}.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true
}


resource "aws_vpc" "ipg" {
  provider             = "aws.ireland"
  cidr_block           = "192.${var.subnet_second_octet}.${var.subnet_third_octet}.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true
}


resource "aws_vpc" "lpg" {
  provider             = "aws.london"
  cidr_block           = "10.${var.subnet_second_octet}.${var.subnet_third_octet}.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true
}


# ===================================================================================================================
# Creating 2 public subnets and 2 private subnets in region us-east-1 (Virginia)
# ===================================================================================================================


resource "aws_subnet" "utility-subnet_v" {
  count             = var.az_count_virginia
  vpc_id            = aws_vpc.vpg.id
  cidr_block        = "172.${var.subnet_second_octet}.${var.subnet_third_octet + 7}.${count.index * 32}/27"
  availability_zone = "${var.region}${var.subnet_identifiers[0]}"

  tags = map(
      "SubnetType", "Utility"
    )

  lifecycle {
    ignore_changes = [tags]
  }
}


resource "aws_subnet" "private-subnet" {
  count             = var.az_count_virginia
  vpc_id            = aws_vpc.vpg.id
  cidr_block        = "172.${var.subnet_second_octet}.${var.subnet_third_octet + (count.index * 2)}.0/23"
  availability_zone = "${var.region}${var.subnet_identifiers[count.index]}"

  tags = map(
      "SubnetType", "Private"
    )

  lifecycle {
    ignore_changes = ["tags"]
  }
}


# ===================================================================================================================
# Creating 1 private subnet in eu-west-1 region (Ireland)
# ===================================================================================================================


resource "aws_subnet" "private-subnet_i" {
  provider          = "aws.ireland"
  vpc_id            = aws_vpc.ipg.id
  cidr_block        = "192.${var.subnet_second_octet}.${var.subnet_third_octet}.0/23"
  availability_zone = "${var.region_ireland}${var.subnet_identifiers[0]}"

  tags = map(
      "SubnetType", "Private"
    )

  lifecycle {
    ignore_changes = [tags]
  }
}


# ===================================================================================================================
# Creating 1 private subnet in eu-west-2 region (London)
# ===================================================================================================================


resource "aws_subnet" "private-subnet_l" {
  provider          = "aws.london"
  vpc_id            = aws_vpc.lpg.id
  cidr_block        = "10.${var.subnet_second_octet}.${var.subnet_third_octet}.0/23"
  availability_zone = "${var.region_london}${var.subnet_identifiers[0]}"

  tags = map(
      "SubnetType", "Private"
    )

  lifecycle {
    ignore_changes = [tags]
  }
}


# ===================================================================================================================
# Creating internet gateways for all 3 regions us-east-1, eu-west-1 & eu-west-2 (Virginia, Ireland & London)
# ===================================================================================================================


resource "aws_internet_gateway" "internet_gateway_v" {
  vpc_id     = aws_vpc.vpg.id
}


resource "aws_internet_gateway" "internet_gateway_i" {
  provider   = "aws.ireland"
  vpc_id     = aws_vpc.ipg.id
}


resource "aws_internet_gateway" "internet_gateway_l" {
  provider   = "aws.london"
  vpc_id     = aws_vpc.lpg.id
}


# ===================================================================================================================
# Creating elastic ips for nat for 2 regions eu-west-1 & eu-west-2 (Ireland & London)
# ===================================================================================================================vvvvvvvvvvv


resource "aws_eip" "elastic_ip_i" {
  provider    = "aws.ireland"
  vpc         = true
}

resource "aws_eip" "elastic_ip_l" {
  provider    = "aws.london"
  vpc         = true
}


# ===================================================================================================================
# Creating nat gateway for 2 regions eu-west-1 & eu-west-2 (Ireland & London)
# ===================================================================================================================


resource "aws_nat_gateway" "nat_gateway_i" {
  provider      = "aws.ireland"
  allocation_id = aws_eip.elastic_ip_i.id
  subnet_id     = aws_subnet.private-subnet_i.id
}


resource "aws_nat_gateway" "nat_gateway_l" {
  provider      = "aws.london"
  allocation_id = aws_eip.elastic_ip_l.id
  subnet_id     = aws_subnet.private-subnet_l.id
}


# =======================================================================================================================================================
# Creating 2 peering connections between vpc. 1st from us-east-1 (virginia) to eu-west-1 (ireland) & 2nd from us-east-1 (virginia) to eu-west-2 (london)
# and vpc in the both remote regions are accepting the connection requests
# =======================================================================================================================================================


# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer1" {
  vpc_id        = aws_vpc.vpg.id
  peer_vpc_id   = aws_vpc.ipg.id
  peer_region   = "eu-west-1"
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer1" {
  provider                  = "aws.ireland"
  vpc_peering_connection_id = aws_vpc_peering_connection.peer1.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}           


# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer2" {
  vpc_id        = aws_vpc.vpg.id
  peer_vpc_id   = aws_vpc.lpg.id
  peer_region   = "eu-west-2"
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer2" {
  provider                  = "aws.london"
  vpc_peering_connection_id = aws_vpc_peering_connection.peer2.id
  auto_accept               = true

  tags = {
   Side = "Accepter"
  }
}           


# ===================================================================================================================
# creating route table (public) and its components for region us-east-1 (Virginia)
# ===================================================================================================================


resource "aws_route_table" "route_table_v" {
  vpc_id = aws_vpc.vpg.id
}

# Creating routes for public route table and public route table for region us-east-1 (Virginia)
resource "aws_route" "default_route_v" {
  route_table_id         = aws_route_table.route_table_v.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway_v.id
}


resource "aws_route" "peering_route_1" {
  route_table_id            = aws_route_table.route_table_v.id
  destination_cidr_block    = aws_vpc.ipg.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer1.id
  depends_on                = [aws_route_table.route_table_v]
}

resource "aws_route" "peering_route_2" {
  route_table_id            = aws_route_table.route_table_v.id
  destination_cidr_block    = aws_vpc.lpg.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer2.id
  depends_on                = [aws_route_table.route_table_v]
}

resource "aws_route_table_association" "utility-subnet-rt-association_v" {
  count          = var.az_count_virginia
  subnet_id      = element(aws_subnet.utility-subnet_v.*.id,count.index)
  route_table_id = aws_route_table.route_table_v.id
}


# ===================================================================================================================
# creating route table (private) and its components for region eu-west-1 (Ireland)
# ===================================================================================================================

# Creating private route table for region eu-west-1 (Ireland)
resource "aws_route_table" "private-subnet-route-table_i" {
  provider      = "aws.ireland"
  vpc_id        = aws_vpc.ipg.id
}

# Creating routes for private route table for region eu-west-1 (Ireland)
resource "aws_route" "private-subnet-nat_route_i" {
  provider               = "aws.ireland"
  route_table_id         = aws_route_table.private-subnet-route-table_i.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_i.id
}

resource "aws_route" "peering_route_3" {
  provider               = "aws.ireland"
  route_table_id            = aws_route_table.private-subnet-route-table_i.id
  destination_cidr_block    = aws_vpc.vpg.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer1.id
  depends_on                = [aws_route_table.private-subnet-route-table_i]
}

# Creating subnets association with private route table for region eu-west-1 (Ireland)
resource "aws_route_table_association" "private-subnet-rt-association_i" {
  provider       = "aws.ireland"
  subnet_id      = aws_subnet.private-subnet_i.id
  route_table_id = aws_route_table.private-subnet-route-table_i.id
}


# ===================================================================================================================
# creating route table (private) and its components for region eu-west-2 (London)
# ===================================================================================================================

# Creating private route table for region eu-west-2 (London)
resource "aws_route_table" "private-subnet-route-table_l" {
  provider      = "aws.london"
  vpc_id        = aws_vpc.lpg.id
}

# Creating routes for private route table for region eu-west-2 (London)
resource "aws_route" "private-subnet-nat_route_l" {
  provider               = "aws.london"
  route_table_id         = aws_route_table.private-subnet-route-table_l.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_l.id
}

resource "aws_route" "peering_route_4" {
  provider               = "aws.london"
  route_table_id            = aws_route_table.private-subnet-route-table_l.id
  destination_cidr_block    = aws_vpc.vpg.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer2.id
  depends_on                = [aws_route_table.private-subnet-route-table_l]
}

# Creating subnets association with private route table for region eu-west-2 (London)
resource "aws_route_table_association" "private-subnet-rt-association_l" {
  provider       = "aws.london"
  count          = var.az_count_london
  subnet_id      = aws_subnet.private-subnet_l.id
  route_table_id = aws_route_table.private-subnet-route-table_l.id
}


# ===================================================================================================================
# Creating dhcp options and dhcp options association with vpc for region us-east-1 (Virginia)
# ===================================================================================================================

resource "aws_vpc_dhcp_options" "vpg" {
  domain_name         = "${var.env}.${var.engineering_domain}"
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "vpg" {
  vpc_id              = aws_vpc.vpg.id
  dhcp_options_id     = aws_vpc_dhcp_options.vpg.id
}
