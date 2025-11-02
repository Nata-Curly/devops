resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = var.vpc_name
  }
}

# Public subnets
resource "aws_subnet" "public" {
  for_each                = { for idx, cidr in var.public_subnets : idx => cidr }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = var.availability_zones[tonumber(each.key) % length(var.availability_zones)]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-${each.key}"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  for_each          = { for idx, cidr in var.private_subnets : idx => cidr }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = var.availability_zones[tonumber(each.key) % length(var.availability_zones)]
  tags = {
    Name = "${var.vpc_name}-private-${each.key}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  # 'vpc' argument removed in newer provider versions; allocation will be used by NAT Gateway
  tags = {
    Name = "${var.vpc_name}-nat-eip"
  }
}

# NAT Gateway placed in the first public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public["0"].id
  tags          = { Name = "${var.vpc_name}-nat" }
}
