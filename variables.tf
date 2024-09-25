variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}

variable "ami_filter" {
  description = "Name filter and Owner for AMI(Amazon machine image)"

  type = object({
    name = string
    owner = string
  })
  default = {
    owners = "979382823631" # Bitnami
    name = "bitnami-tomcat-*-x86_64-hvm-ebs-nami"
  }
  
}
#VPC'S
# data "aws_vpc" "default" {
#   default = true
# }
variable "environment" {
    description = "Developmnent Env"

    type = object({
        name = string
        network_prefix = string
    })
    default = {
        name = "dev"
        network_prefix = "10.0"
    }
}

variable "asg_min_size" {
    description = "Minimum number of instances"
    default = 1
}


variable "asg_max_size" {
    description = "Maximum number of instances"
    default = 2
}



