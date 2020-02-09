variable nginx {
  type = object({
    name = string
    port = number
    image = string
  })
  default =  {
    name  = "nginx"
    port  = 80
    image = "docker.io/nginx:latest"
  }
  description = "nginx variables for the service definition"
}

resource "aws_cloudwatch_log_group" "nginx_group" {
  name = format("/%s/%s/%s", var.environment, "ecs" , var.nginx.name )
  tags = {
    Environment = var.environment
  }
}

module "frontend-task-definition" {
  source = "github.com/chehabz/terraform-aws-ecs-task-definition"

  family = format("%s-%s", var.environment, var.nginx.name)
  image  = var.nginx.image
  memory = 2048
  cpu    = 2048
  name   = var.nginx.name

  portMappings = [
    {
      containerPort = var.nginx.port
      hostPort = 0
    }
  ]
  environment = [
    
    {
      name   = "SOME_ENVIRONMENT_VARIABLE"
      value = "SOME_VALUE"
    }
  ]


  logConfiguration = {
    logDriver = "awslogs"
    options = {
      awslogs-group  = format("/%s/%s/%s", var.environment, "ecs", var.nginx.name)
      awslogs-region = var.region
    },
  }

  requires_compatibilities = [ "EC2" ]

  //@fixme!!!!
  task_role_arn="arn:aws:iam::066385659883:role/ECSTaskExecutionRole"
  execution_role_arn="arn:aws:iam::066385659883:role/ECSTaskExecutionRole"
}

/**
* create the service
**/
resource "aws_ecs_service" "nginx_service" {
  cluster         = var.cluster_id
  name            = format("%s-%s", var.nginx.name, "svc")
  task_definition = module.nginx-task-definition.arn
  desired_count   = 1
  
  load_balancer {
    target_group_arn = var.target_group_arns[0]
    container_name   = var.nginx.name
    container_port   = var.nginx.port
  }
  
  service_registries  {
    registry_arn   = aws_service_discovery_service.nginx_discovery_service.arn
    container_port = var.nginx.port
    container_name = var.nginx.name
  }

}

/**
* create the name record in the discovery service
**/
resource "aws_service_discovery_service" "nginx_discovery_service" {
  name = format("%s-%s", var.nginx.name, "svc" )

  dns_config {
    namespace_id = var.ecs_service_discovery_id

    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }
}