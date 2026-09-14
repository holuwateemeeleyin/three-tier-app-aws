variable "aws_region" {
  description = "AWS region where resource will be deployed"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

# Create availability zones variable for the architecture
# Here we are using two zones, which are eu-west-1a and eu-west-1b
variable "availability_zones" {
  description = "Availability Zones for the architecture"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}


# EC2 instance type for the web tier.
variable "web_instance_type" {
  description = "EC2 instance type for the web servers"
  type        = string
  default     = "t3.micro"
}

# EC2 instance type for the application tier.
variable "app_instance_type" {
  description = "EC2 instance type for the application servers"
  type        = string
  default     = "t3.micro"
}

# RDS instance class for the database tier.
variable "db_instance_class" {
  description = "RDS instance class for PostgreSQL"
  type        = string
  default     = "db.t3.micro"
}