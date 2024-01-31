variable "aws_region" {
  default = "us-west-2"
}


variable "environment_name" {
  default = " "
}

variable "project_name" {
  default = " "
}

variable "cluster_name" {
  default = " "
}

variable "vpc_id" {
  type = string
}


variable "subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}


variable "cluster_version" {
  default = " "
}

variable "enabled_cluster_log_types" {
  type = list(string)
}

variable "cluster_endpoint_public_access" {
  default = " "
}

variable "on_demand_instance_types" {
  type = list(string)
  default = [ "t3.medium" ]
}
variable "spot_instance_types" {
  type = list(string)
  default = [ "t3.large" ]
}
variable "create_on_demand_ng" {
  type= bool
  default = true  
}
variable "create_spot_ng" {
  type= bool
  default = false
}
variable "eks_spot_min_size" {
  type = number
  default = 1
  
}
variable "eks_spot_max_size" {
  type = number
  default = 1
  
}
variable "eks_spot_desired_size" {
  type = number
  default = 1
  
}

variable "eks_on_demand_min_size" {
  type = number
  default = 1
  
}
variable "eks_on_demand_max_size" {
  type = number
  default = 1
  
}
variable "eks_on_demand_desired_size" {
  type = number
  default = 1
  
}
variable "aws_profile_name" {
  type = string
  default= "default"
  
}

variable "enable_cluster_autoscaler" {
  type    = bool
  default = false

}
variable "enable_cluster_karpenter" {
  type    = bool
  default = true

}
