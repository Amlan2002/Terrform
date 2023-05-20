variable "public_subnet_cidr" {
  type = list(string)
  default = ["18.0.2.0/23","18.0.4.0/23"]
}

variable "private_subnet_cidr" {
  type = list(string)
  default = ["18.0.12.0/23","18.0.14.0/23"]
}