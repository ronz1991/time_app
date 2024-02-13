terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-west-2" 
}

provider "kubernetes" {}

# Create VPC
resource "aws_vpc" "time_app_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.time_app.id
}

# Create Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.time_app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Create Subnet
resource "aws_subnet" "time_app" {
  vpc_id            = aws_vpc.time_app.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a" 
}

# Create Security Group
resource "aws_security_group" "my_security_group" {
  vpc_id = aws_vpc.time_app.id

  # Allow HTTP traffic
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Route Table Association
resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.time_app.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create ECR Repository
resource "aws_ecr_repository" "ron" {
  name = "time_app"
}

# Create EKS Cluster
module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.0.0"

  cluster_name    = "ron-eks-cluster"
  cluster_version = "1.21"

  vpc_id              = aws_vpc.time_app.id
  subnet_ids          = [aws_subnet.time_app.id]
  map_public_ip_on_launch = true

  node_groups = {
    eks_workers = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.medium"
    }
  }

  tags = {
    Environment = "test"
  }
}

# Deploy Python application deployment
resource "kubernetes_deployment" "time_app_deployment" {
  metadata {
    name      = "time_app"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "time_app"
      }
    }

    template {
      metadata {
        labels = {
          app = "time_app"
        }
      }

      spec {
        containers {
          name  = "time_app"
          image = "${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/time_app:latest"

          ports {
            container_port = 8080
          }
        }
      }
    }
  }
}

# Expose Python application service
resource "kubernetes_service" "time_app_service" {
  metadata {
    name      = "time_app"
    namespace = "default"
  }

  spec {
    selector = {
      app = "time_app"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

