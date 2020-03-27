resource "aws_security_group" "mgmt_lb" {
  name        = "${var.deployment}-mgmt-lb"
  description = "${var.deployment}-mgmt-lb"

  vpc_id = aws_vpc.hub.id
}

module "mgmt_lb_can_talk_to_prometheus" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.mgmt_lb.id
  destination_sg_id = aws_security_group.prometheus.id

  port = 9090
}

resource "aws_security_group_rule" "mgmt_lb_ingress_from_internet_over_http" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = aws_security_group.mgmt_lb.id
  cidr_blocks       = var.mgmt_accessible_from_cidrs
}

resource "aws_security_group_rule" "mgmt_lb_ingress_from_internet_over_https" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = aws_security_group.mgmt_lb.id
  cidr_blocks       = var.mgmt_accessible_from_cidrs
}

resource "aws_lb" "mgmt" {
  name               = "${var.deployment}-mgmt"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.mgmt_lb.id]
  subnets         = aws_subnet.ingress.*.id

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_lb_listener" "mgmt_http" {
  load_balancer_arn = aws_lb.mgmt.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "🛠️"
      status_code  = "200"
    }
  }
}
