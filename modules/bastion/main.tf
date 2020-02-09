
resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group" "bastion_sg" {
  name   = format("%s-%s", var.environment, "bastion-sg")
  vpc_id = var.vpc_id

  tags = {
    Environment = var.environment
  }
}

resource "aws_route53_record" "bastion_cname" {
  zone_id = var.public_zone_id
  name    = format("%s.%s.%s", "bastion", var.environment, var.public_domain_name)
  type    = "A"
  ttl     = "5"
  records = [aws_instance.bastion.public_ip]
}

resource "aws_instance" "bastion" {
  ami           = "ami-01de9443606bda731"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_iam.name
  key_name               = var.key_name
  subnet_id              = length(var.public_subnets_ids) > 0 ? var.public_subnets_ids[0] : ""
  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_instance_profile" "bastion_iam" {
  name = format("%s-%s", var.environment, "bastion_iam")
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_role" "bastion_role" {
  name               = format("%s-%s", var.environment, "bastion_role")
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.default.json
}

data "aws_iam_policy_document" "default" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }
}
