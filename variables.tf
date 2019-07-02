variable "region" {
  default = "us-east-1"
}

variable "amis" {
  type = "map"

  default {
    "us-east-1" = "ami-0a313d6098716f372"
  }
}

variable "ssh_pub_key" {
  default = "..."
}

variable "private_subnets" {
  default = ["10.0.1.0/24", "10.0.10.0/24"]
}

variable "vpc_subnet" {
  default = "10.0.0.0/16"
}

variable "your_subnet" {
  default = "..."
}