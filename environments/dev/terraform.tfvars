aws_region           = "ap-southeast-2"
environment          = "dev"
key_pair_name        = "aws_login_dev"
vpc_cidr             = "10.10.0.0/16"
availability_zones   = ["ap-southeast-2a", "ap-southeast-2b"]
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]

instance_type    = "t3.small" #"t3.micro"
min_size         = 2
max_size         = 4
desired_capacity = 2


git_repo_url="https://github.com/Manishdgithub/terraform-infra-eks-zero-touch.git"
git_target_branch="main"
kubernetes_deployment_file_name="2048-game.yaml"
