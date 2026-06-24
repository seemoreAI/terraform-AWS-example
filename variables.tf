# Variables
# Some sensitive information
variable "v-access-key" {
  description = "AWS access key"
  type        = string
}

variable "v-secret-key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}


variable "v-region" {
  description = "AWS region"
  type        = string
}

variable "v-ami-image" {
  description = "AMI image for EC2 instances"
  type        = string
}

variable "v-instance-type" {
  description = "EC2 instance type"
  type        = string
}

variable "v-instance-key" {
  description = "SSH key pair name"
  type        = string
}

variable "v-count" {
  description = "Number of subnets and EC2 instances"
  type        = number
}

variable "do1-cidr" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
}

data "aws_availability_zones" "do1-avz" {}