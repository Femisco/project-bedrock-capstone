provider "aws" {
  region = "us-east-1"
}

# --------------------
# VPC
# --------------------
resource "aws_vpc" "bedrock_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "project-bedrock-vpc"
    Project = "barakat-2025-capstone"
  }
}

# --------------------
# Internet Gateway
# --------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.bedrock_vpc.id

  tags = {
    Name    = "project-bedrock-igw"
    Project = "barakat-2025-capstone"
  }
}

# --------------------
# Public Subnets
# --------------------
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.bedrock_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "project-bedrock-public-1"
    Project = "barakat-2025-capstone"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.bedrock_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "project-bedrock-public-2"
    Project = "barakat-2025-capstone"
  }
}

# --------------------
# Private Subnets
# --------------------
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.bedrock_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name    = "project-bedrock-private-1"
    Project = "barakat-2025-capstone"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.bedrock_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name    = "project-bedrock-private-2"
    Project = "barakat-2025-capstone"
  }
}

# --------------------
# Public Route Table
# --------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.bedrock_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "project-bedrock-public-rt"
    Project = "barakat-2025-capstone"
  }
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# --------------------
# NAT Gateway (single, cost-controlled)
# --------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name    = "project-bedrock-nat-eip"
    Project = "barakat-2025-capstone"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name    = "project-bedrock-nat"
    Project = "barakat-2025-capstone"
  }
}

# --------------------
# Private Route Table
# --------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.bedrock_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name    = "project-bedrock-private-rt"
    Project = "barakat-2025-capstone"
  }
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_iam_role" "eks_cluster_role" {
  name = "project-bedrock-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "barakat-2025-capstone"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role" "eks_node_role" {
  name = "project-bedrock-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "barakat-2025-capstone"
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_worker" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_ecr" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_eks_cluster" "bedrock" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {
    subnet_ids = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id
    ]
  }

  tags = {
    Project = "barakat-2025-capstone"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
resource "aws_eks_node_group" "bedrock_nodes" {
  cluster_name    = aws_eks_cluster.bedrock.name
  node_group_name = "project-bedrock-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.small"]

  tags = {
    Project = "barakat-2025-capstone"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker,
    aws_iam_role_policy_attachment.eks_node_cni,
    aws_iam_role_policy_attachment.eks_node_ecr
  ]
}
resource "aws_s3_bucket" "assets" {
  bucket = "bedrock-assets-alt-soe-024-4718"

  force_destroy = false

  tags = {
    Project = "barakat-2025-capstone"
  }
}

resource "aws_s3_bucket_public_access_block" "assets_block" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_iam_user" "bedrock_dev_view" {
  name = "bedrock-dev-view"

  tags = {
    Project = "barakat-2025-capstone"
  }
}

resource "aws_iam_policy" "assets_put_policy" {
  name = "bedrock-assets-put-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })

  tags = {
    Project = "barakat-2025-capstone"
  }
}

resource "aws_iam_user_policy_attachment" "assets_put_attach" {
  user       = aws_iam_user.bedrock_dev_view.name
  policy_arn = aws_iam_policy.assets_put_policy.arn
}

resource "aws_iam_access_key" "bedrock_dev_key" {
  user = aws_iam_user.bedrock_dev_view.name
}
