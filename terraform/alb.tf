# Application Load Balancer
# This is the public entry point for users accessing the application.
resource "aws_lb" "main" {
  name               = "three-tier-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name        = "three-tier-alb"
    Environment = var.environment
  }
}

# Target Group
# The target group contains the web servers that will receive
# traffic from the Application Load Balancer.
resource "aws_lb_target_group" "web" {
  name     = "three-tier-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name        = "three-tier-web-tg"
    Environment = var.environment
  }
}


# ALB Listener
# The listener waits for incoming requests on port 80
# and forwards them to the web target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}