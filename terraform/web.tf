# Get the latest Amazon Linux 2023 AMI.
# We use the AWS Systems Manager public parameter instead
# of hardcoding an AMI ID because AMI IDs are different
# across AWS regions.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}


# Web Server EC2 Instances
# Create one Nginx server in each Availability Zone.
resource "aws_instance" "web" {
  count = 2

  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = var.web_instance_type
  subnet_id     = aws_subnet.web[count.index].id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  user_data = <<-EOF
              #!/bin/bash

              # Update installed packages.
              dnf update -y

              # Install Nginx.
              dnf install -y nginx

              # Start Nginx immediately.
              systemctl start nginx

              # Make sure Nginx starts automatically after reboot.
              systemctl enable nginx

              # Create a simple page so we can test
              # that the web server is working.
              cat > /usr/share/nginx/html/index.html <<HTML
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Three Tier Application</title>
              </head>
              <body>
                  <h1>Web Tier is Working</h1>
                  <p>Nginx server: ${count.index + 1}</p>
              </body>
              </html>
              HTML
              EOF

  tags = {
    Name        = "web-server-${count.index + 1}"
    Environment = var.environment
    Tier        = "web"
  }
}


# Register the web servers with the ALB target group
# This allows the ALB to send traffic to the EC2 instances
resource "aws_lb_target_group_attachment" "web" {
  count = 2

  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}