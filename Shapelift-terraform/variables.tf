variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
  
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "terraform-windows"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}
