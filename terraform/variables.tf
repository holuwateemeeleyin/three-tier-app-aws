variable "aws_region" {
    description = "AWS region where resource will be deployed"
    type        = string
    default     = "eu-west-1"
}

variable "environment"{
    description = "Deployment environment"
    type        = string 
    default     = "dev"
}