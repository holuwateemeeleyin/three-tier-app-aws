# RDS Subnet Group
# RDS requires subnets in at least two Availability Zones
# for a Multi-AZ database deployment.
resource "aws_db_subnet_group" "database" {
  name = "three-tier-db-subnet-group"

  # Place the database in the two isolated database subnets.
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name        = "three-tier-db-subnet-group"
    Environment = var.environment
  }
}


# PostgreSQL RDS Database
# This is the database tier of the three-tier architecture.
resource "aws_db_instance" "postgres" {
  engine = "postgres"
  instance_class = var.db_instance_class
  allocated_storage = 20
  storage_encrypted = true
  multi_az = true
  db_subnet_group_name = aws_db_subnet_group.database.name

  # Only the application tier can connect to PostgreSQL.
  vpc_security_group_ids = [
    aws_security_group.database.id
  ]

  # Prevent the database from being directly accessible from the public internet.
  publicly_accessible = false

  # Database credentials.
  # The password is managed by AWS Secrets Manager instead of being stored directly in this Terraform configuration.
  username                  = var.db_username
  manage_master_user_password = true
  
  backup_retention_period = 1
  apply_immediately = true
  skip_final_snapshot = true
  deletion_protection = false
  copy_tags_to_snapshot = true

  tags = {
    Name        = "three-tier-postgres"
    Environment = var.environment
    Tier        = "database"
  }
}