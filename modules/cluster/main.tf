/**
/* create the cluster
/**/
resource "aws_ecs_cluster" "ecs" {
  name = var.name
  tags = {
    Environment = var.environment
  }
}


/**
/* setup cloud watch for monitoring
/**/

resource "aws_cloudwatch_log_group" "instance" {
  name = format("%s/%s/worker-nodes", var.environment, var.name)
  tags = {
    Environment = var.environment
  }
}

/**
/* setup the access control policy to allow instance to put metrics inside the cloudwatch
/**/
data "aws_iam_policy_document" "instance_policy" {
  statement {
    sid = "CloudwatchPutMetricData"

    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "InstanceLogging"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]

    resources = [
      aws_cloudwatch_log_group.instance.arn,
    ]
  }
}

resource "aws_iam_policy" "instance_policy" {
  name   = format("%s-%s", var.name, "ECS-Instance")
  path   = "/"
  policy = data.aws_iam_policy_document.instance_policy.json
}

resource "aws_iam_role" "instance" {

  name               = format("%s-%s", var.name, "Instance-Role")
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "instance_policy" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance_policy.arn
}

resource "aws_iam_instance_profile" "instance" {
  name = format("%s-%s-%s", var.environment, var.name, "instance-profile")
  role = aws_iam_role.instance.name
}

/**
* prepare environment variables for the instance
**/
data "template_file" "user_data" {
  template = file(format("%s/%s", path.module, "user_data.sh"))

  vars = {
    additional_user_data_script = var.additional_user_data_script
    ecs_cluster                 = aws_ecs_cluster.ecs.name
    log_group                   = aws_cloudwatch_log_group.instance.name
  }
}

/**
* seperate security group from the load balancer
* specifically for the instance
**/

resource "aws_security_group" "instance_sg" {
  name   = format("%s-%s", var.environment, "ec2-sg")
  vpc_id = var.vpc_id

  tags = {
    Environment = var.environment
  }
}

/**
* only accept traffic from the alb security group as ingress
**/
resource "aws_security_group_rule" "ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "TCP"
  source_security_group_id = var.sg_alb_id
  security_group_id        = aws_security_group.instance_sg.id
}

//accept ssh from the bastion, and port rds
resource "aws_security_group_rule" "bastion_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "TCP"
  source_security_group_id = var.bastion_sg_id
  security_group_id        = aws_security_group.instance_sg.id
}

resource "aws_security_group_rule" "bastion_postgress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "TCP"
  source_security_group_id = var.bastion_sg_id
  security_group_id        = aws_security_group.instance_sg.id
}


resource "aws_security_group_rule" "ec2_postgress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.instance_sg.id
  security_group_id        = aws_security_group.instance_sg.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instance_sg.id
}

resource "aws_launch_configuration" "instance" {
  name_prefix          = format("%s-%s", var.name, "lc")
  image_id             = var.ecs_aws_ami
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.instance.name
  user_data            = data.template_file.user_data.rendered
  security_groups      = [aws_security_group.instance_sg.id]
  key_name             = var.key_pair_name

  root_block_device {
    volume_size = 50 //@TODO: 15 GiB to be changed later to a variable probably
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name = format("%s-%s", var.name, "sg")

  launch_configuration = aws_launch_configuration.instance.name
  vpc_zone_identifier  = var.vpc_subnets
  max_size             = var.max_size
  min_size             = var.min_size
  desired_capacity     = var.desired_capacity

  health_check_grace_period = 300
  health_check_type         = "EC2"

  lifecycle {
    create_before_destroy = true
  }
}