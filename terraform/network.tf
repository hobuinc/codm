resource "aws_vpc" "engine-vpc" {
    cidr_block           = "12.0.0.0/16"
    enable_dns_hostnames = false
    enable_dns_support   = true
}


locals {
  azs = [ for x in data.aws_availability_zone.available : x.name ]
}

resource "aws_subnet" "worker-subnets" {
    count = length(local.azs)
    vpc_id = aws_vpc.engine-vpc.id
    #cidr_block = "12.0.2.0/24"
    cidr_block              = "12.0.${count.index}.0/24"
    availability_zone       = local.azs[count.index]
    map_public_ip_on_launch = true
}

resource "aws_route_table_association" "subnet-route-connections" {
        count = length(aws_subnet.worker-subnets)
        subnet_id      = aws_subnet.worker-subnets[count.index].id
        route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table" "route-table" {
    vpc_id = aws_vpc.engine-vpc.id
}

resource "aws_route" "InternetGatewayConnect" {
  route_table_id         = aws_route_table.route-table.id
  gateway_id             = aws_internet_gateway.gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.engine-vpc.id
}

resource "aws_security_group" "worker-security-group" {
    name        = "WorkerSecurityGroup"
    description = "Security group for coord worker instances"
   ingress {
     protocol    = "tcp"
     from_port   = 22
     to_port     = 22
     cidr_blocks = ["0.0.0.0/0"]
   }
    egress {
        protocol    = "tcp"
        from_port   = 0
        to_port     = 65535
        cidr_blocks = ["0.0.0.0/0"]
    }
    vpc_id = aws_vpc.engine-vpc.id
}

output "workerSubnetList" {
    description = "Array of subnets that coord workers may be spawned in"
    value = [ for s in aws_subnet.worker-subnets : s.id ]
}

