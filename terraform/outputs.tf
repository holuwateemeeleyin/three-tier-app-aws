# VPC ID
output "vpc_id" {
  description = "ID of the three-tier VPC"
  value       = aws_vpc.main.id
}


# Application Load Balancer DNS name
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}


# RDS endpoint
# The private endpoint that the application tier will use to connect to PostgreSQL.
output "rds_endpoint" {
  description = "Private endpoint of the PostgreSQL database"
  value       = aws_db_instance.postgres.address
}


# RDS port
output "rds_port" {
  description = "PostgreSQL database port"
  value       = aws_db_instance.postgres.port
}


# RDS managed secret
output "rds_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master password"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
  sensitive   = true
}