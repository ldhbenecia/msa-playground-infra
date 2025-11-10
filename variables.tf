variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID for Seoul region"
  type        = string
  default     = "ami-0a71e3eb8b23101ed" # t3.micro와 호환되는 AMI
}

variable "key_name" {
  description = "EC2 Key Pair Name"
  type        = string
}
