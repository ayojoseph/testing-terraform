data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}
#VPC'S
# data "aws_vpc" "default" {
#   default = true
# }

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs             = ["ca-central-1a", "ca-central-1b", "ca-central-1d"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}

#INSTANCES
# resource "aws_instance" "blog" {
#   ami           = data.aws_ami.app_ami.id
#   instance_type = var.instance_type

#   # vpc_security_group_ids = [aws_security_group.blog.id]
#   vpc_security_group_ids = [module.blog_sg.security_group_id]

#   subnet_id = module.blog_vpc.public_subnets[0]
  
#   tags = {
#     Name = "HelloWorld"
#   }
# }

#AUTOSCALING

module "blog_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.5.2"
  

  # Autoscaling group
  name = "${var.environment.name}-blog"
  min_size = var.asg_min_size
  max_size = var.asg_max_size

  vpc_zone_identifier = module.blog_vpc.public_subnets
  target_group_arns = module.blog_alb.target_group_arns
  security_groups = [module.blog_sg.security_group_id]

  image_id = data.aws_ami.app_ami.id
  instance_type = var.instance_type
}

#LOAD BALANCER
module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name    = "${var.environment.name}-blog-alb"

  load_balancer_type = "application"

  vpc_id  = module.blog_vpc.vpc_id
  subnets = module.blog_vpc.public_subnets

  # Security Group
  security_groups = [module.blog_sg.security_group_id]


  target_groups = [
    {
      name_prefix      = "${var.environment.name}-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = var.environment.name
  }
}

# SECURITY GROUPS
module "blog_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.13.0"
  name        = "${var.environment.name}-blog"
  description = "Setting up new security group using module"

  vpc_id = module.blog_vpc.vpc_id

  ingress_rules       = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}


