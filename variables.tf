variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "region_ireland" {
  description = "AWS Region"
  default     = "eu-west-1"
}

variable "region_london" {
  description = "AWS Region"
  default     = "eu-west-2"
}


variable "az_count_virginia" {
  description = "Number of subnets / Availability zones to use"
  default     = "2"
}

variable "az_count_ireland" {
  description = "Number of subnets / Availability zones to use"
  default     = "3"
}

variable "az_count_london" {
  description = "Number of subnets / Availability zones to use"
  default     = "3"
}

variable "env" {
  description = "Environment"
  default     = "dev"
}


variable "engineering_domain" {
  description = "DNS zone"
  default     = "example.net"
}


variable "subnet_second_octet" {
  description = "Second Octet of the network"
  default     = "15"
}

variable "subnet_third_octet" {
  description = "Third Octet of the network"
  default     = "192"
}

variable "peers" {
  description = "List of Maps"
  type        = list(map(string))
  default     = []
}

variable "subnet_identifiers" {
  description = "List of AZs"
  type        = list
  default     = ["a", "b", "c"]
}
