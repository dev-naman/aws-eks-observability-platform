module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }


  endpoint_public_access = true

  create_iam_role = false

  iam_role_arn = var.eks_cluster_role_arn

  enable_irsa = true

  eks_managed_node_groups = {
    default = {

      create_iam_role = false

      iam_role_arn = var.eks_node_role_arn

      instance_types = ["t2.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}
