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

  # Encrypt the web server root volume.
  root_block_device {
    encrypted = true
  }

  # Automatically install and configure Nginx
  # when the EC2 instance is launched.
  user_data = <<-EOF
              #!/bin/bash

              
              dnf update -y
              dnf install -y nginx

              # Configure Nginx as a reverse proxy.
              # Requests received by Nginx will be forwarded
              # to the Node.js application servers.
              cat > /etc/nginx/conf.d/app.conf <<NGINX
              upstream node_app {
                  server ${aws_instance.app[0].private_ip}:3000;
                  server ${aws_instance.app[1].private_ip}:3000;
              }

              server {
                  listen 80;
                  server_name _;

                  location / {
                      proxy_pass http://node_app;

                      proxy_set_header Host \$host;
                      proxy_set_header X-Real-IP \$remote_addr;
                      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                      proxy_set_header X-Forwarded-Proto \$scheme;
                  }
              }
              NGINX

              # Test the Nginx configuration before starting it.
              nginx -t
              
              # Start the Nginx service.
              systemctl start nginx

              # To make sure Nginx starts automatically after reboot.
              systemctl enable nginx
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