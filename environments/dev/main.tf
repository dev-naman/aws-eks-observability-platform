module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "dev-vpc"

  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

module "iam" {

  source = "../../modules/iam"

  environment = "dev"
}


module "eks" {

  source = "../../modules/eks"

  cluster_name = "dev-demo-eks"

  cluster_version = "1.33"

  vpc_id = module.vpc.vpc_id

  private_subnet_ids = module.vpc.private_subnets

  eks_cluster_role_arn = module.iam.eks_cluster_role_arn

  eks_node_role_arn = module.iam.eks_node_role_arn
}