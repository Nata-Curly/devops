variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of CIDRs for public subnets"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of CIDRs for private subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AZs to place subnets into"
}

variable "vpc_name" {
  type        = string
  description = "Name tag for the VPC"
}
