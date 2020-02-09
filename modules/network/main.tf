resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  vpc = true
}

module "http_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "~> 3.0"

  name        = "http-sg-egress-allow-all"
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = format("%s_%s", var.app_name, var.environment)
  cidr = var.vpc_cidr

  public_subnet_suffix  = "public"
  private_subnet_suffix = "private"

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  reuse_nat_ips       = true
  external_nat_ip_ids = aws_eip.nat.*.id

  #https://aws.amazon.com/blogs/aws/new-vpc-endpoint-for-amazon-s3/
  enable_s3_endpoint = true

  enable_dns_hostnames               = true
  enable_dns_support                 = true
  enable_apigw_endpoint              = true
  apigw_endpoint_private_dns_enabled = true
  apigw_endpoint_security_group_ids  = [module.http_sg.this_security_group_id]


  tags = {
    Environment = var.environment
  }
}


## security resource groups

resource "aws_security_group" "alb" {
  name   = format("%s-%s-%s", var.app_name, var.environment, "alb-sg")
  vpc_id = module.vpc.vpc_id

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "http_from_anywhere" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = [var.allow_cidr_block]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "https_from_anywhere" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = [var.allow_cidr_block]
  security_group_id = aws_security_group.alb.id
}


resource "aws_security_group_rule" "outbound_internet_access" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

## application load balancer
module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "~> 5.0"
  load_balancer_type = "application"

  name = format("%s%s", var.environment, var.app_name)

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.alb.id]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.ssl_certificate_arn
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name                 = format("%s-%s", "tg", var.environment)
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-299"
      }
      stickiness = {
        enabled         = true
        cookie_duration = 30
        type            = "lb_cookie"
      }
    },
  ]

  tags = {
    Environment = var.environment
  }
}

/**
* redirect http to https 
* we are going to use this listener to attach all the rules on it.
*/
resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = module.alb.this_lb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

/**  
* block requests coming from my custom dns name 
* only allow requests coming from the origin
**/
resource "aws_lb_listener_rule" "frontend" {

  listener_arn = module.alb.https_listener_arns[0]
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arns[0]
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  depends_on = [module.alb.target_group_arns]
}

/**
* each service would require a listener
* todo: the developers must implement nginx!!!!!!!!

resource "aws_lb_listener_rule" "search" {
  listener_arn = module.alb.https_listener_arns[0]
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arns[1]
  }

  condition {
    path_pattern {
      values = ["/search*"]
    }
  }
  
  depends_on = [module.alb.target_group_arns]
}

resource "aws_lb_listener_rule" "core" {
  listener_arn = module.alb.https_listener_arns[0]
  priority     = 102

  action {
    type             = "forward"
    target_group_arn = length(module.alb.target_group_arns) > 2 ? module.alb.target_group_arns[2] : ""
  }

  condition {
    path_pattern {
      values = ["/services*"]
    }
  }
  
  depends_on = [module.alb.target_group_arns]
}
**/