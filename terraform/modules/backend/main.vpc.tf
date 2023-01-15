resource "aws_vpc" "main" {
  cidr_block = var.VPC_cidr
  
  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
  }
}


resource "aws_route_table" "ig_egress_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  depends_on = [aws_vpc.main]
  tags = {
    Name = "example"
  }
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.ig_egress_route_table.id
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${split(".", var.VPC_cidr)[0]}.${split(".", var.VPC_cidr)[1]}.${split(".", var.VPC_cidr)[2] + count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  depends_on              = [aws_vpc.main]

  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "PublicSubnet"
  }
}

resource "aws_subnet" "private_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${split(".", var.VPC_cidr)[0]}.${split(".", var.VPC_cidr)[1]}.${split(".", var.VPC_cidr)[2] + count.index + length(data.aws_availability_zones.available.names)}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  depends_on              = [aws_vpc.main]

  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "PrivateSubnet"
  }
}

resource "aws_internet_gateway_attachment" "ig_attachment" {
  internet_gateway_id = aws_internet_gateway.ig.id
  vpc_id              = aws_vpc.main.id
  depends_on = [aws_internet_gateway.ig]
}

resource "aws_internet_gateway" "ig" {
    tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "InternetGateway"
  }

}