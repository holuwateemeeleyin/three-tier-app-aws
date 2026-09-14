# Get the latest Amazon Linux 2023 AMI.
# The same AMI used by the web servers is used here.
data "aws_ssm_parameter" "al2023_app" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}


# Application Server EC2 Instances
# Create one Node.js application server in each Availability Zone.
resource "aws_instance" "app" {
  count = 2

  ami           = data.aws_ssm_parameter.al2023_app.value
  instance_type = var.app_instance_type
  subnet_id     = aws_subnet.app[count.index].id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  # Encrypt the EC2 root volume.
  # This protects data stored on the server if the disk is accessed.
  root_block_device {
    encrypted = true
  }

  # Install Node.js and create a simple application when the EC2 instance is launched.
  user_data = <<-EOF
              #!/bin/bash

              # Update installed packages.
              dnf update -y

              # Install Node.js and npm.
              dnf install -y nodejs npm

              # Create the application directory.
              mkdir -p /opt/app

              # Create a simple Node.js application.
              cat > /opt/app/server.js <<'NODE'
              const http = require("http");

              const server = http.createServer((req, res) => {
                res.writeHead(200, {
                  "Content-Type": "application/json"
                });

                res.end(JSON.stringify({
                  status: "healthy",
                  message: "Application tier is working"
                }));
              });

              server.listen(3000, "0.0.0.0", () => {
                console.log("Node.js application running on port 3000");
              });
              NODE

              # Create a systemd service so the application
              # automatically starts and restarts when needed.
              cat > /etc/systemd/system/node-app.service <<'SERVICE'
              [Unit]
              Description=Three Tier Node.js Application
              After=network.target

              [Service]
              Type=simple
              User=root
              WorkingDirectory=/opt/app
              ExecStart=/usr/bin/node /opt/app/server.js
              Restart=on-failure
              RestartSec=5

              [Install]
              WantedBy=multi-user.target
              SERVICE

              # Reload systemd so it recognizes the new service.
              systemctl daemon-reload

              # Enable the application to start automatically.
              systemctl enable node-app

              # Start the application.
              systemctl start node-app
              EOF

  tags = {
    Name        = "app-server-${count.index + 1}"
    Environment = var.environment
    Tier        = "app"
  }
}