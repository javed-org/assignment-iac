# vpc module
module "vpc" {
  ############################ VPC VARIABLES ##########################
  source                     = "./modules/vpc"
  project_name               = var.project_name
  aws_region                 = var.aws_region
  vpc_cidr_block             = "10.0.0.0/16"
  environment_name           = var.environment_name

  public_subnet_cidr_blocks  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"]

}
# ECR module
module "ecr" {
############################ ECR VARIABLES #############################
  source                           = "./modules/ecr"
  project_name = var.project_name
  repo_name = var.repo_name
  environment_name = var.environment_name
}

# EKS module
module "eks" {
############################ EKS VARIABLES #############################
  source                           = "./modules/eks"
  aws_region = var.aws_region
  project_name = var.project_name
  environment_name = var.environment_name
  aws_profile_name = var.aws_profile_name
  cluster_version  = "1.27"
  cluster_endpoint_public_access = "true"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets_id
  private_subnet_ids = module.vpc.private_subnets_id
  enabled_cluster_log_types    = ["audit", "api", "authenticator","scheduler"]
  create_on_demand_ng        = true                      #by default true   #values= yes or false
  on_demand_instance_types   = ["c5.large", "t3.small"]  # default t3.medium
  eks_spot_desired_size      = 1                         # default 1
  eks_spot_min_size          = 1                         # default 1
  eks_spot_max_size          = 3                         # default 1
  create_spot_ng             = false                     # by default false  # values= yes or false
  spot_instance_types        = ["t3.large", "t3.medium"] #  default t3.large
  eks_on_demand_desired_size = 1                         # default 1
  eks_on_demand_min_size     = 1                         # default 1
  eks_on_demand_max_size     = 3                         # default 1
  enable_cluster_autoscaler = true
  enable_cluster_karpenter  = false
}

