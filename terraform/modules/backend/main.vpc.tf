resource "aws_vpc" "main" {
  cidr_block = var.VPC_cidr

  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
  }
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
