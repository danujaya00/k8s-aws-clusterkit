# # File: modules/load_balancer/main.tf

# resource "aws_lb" "k8s_alb" {
#   name               = "k8s-alb"
#   load_balancer_type = "application"
#   security_groups    = [var.alb_sg]
#   subnets            = var.vpc_subnet
#   tags = {
#     Name = "k8s-alb"
#   }
# }

# resource "aws_lb_listener" "k8s_listener_http" {
#   load_balancer_arn = aws_lb.k8s_alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.k8s_tg.arn
#   }
# }

# resource "aws_lb_target_group" "k8s_tg" {
#   name        = "k8s-tg-http"
#   port        = 30080
#   protocol    = "HTTP"
#   target_type = "instance"
#   vpc_id      = var.vpc_id

#   health_check {
#     path                = "/"
#     protocol            = "HTTP"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#   }

#   tags = {
#     Name = "k8s-tg-http"
#   }
# }

# resource "aws_autoscaling_attachment" "asg_attachment_http" {
#   autoscaling_group_name = var.autoscaling_group_name
#   lb_target_group_arn    = aws_lb_target_group.k8s_tg.arn
# }
