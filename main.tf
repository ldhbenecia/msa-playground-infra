terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "msa_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "msa-vpc"
  }
}

# Public Subnet A
resource "aws_subnet" "msa_subnet_a" {
  vpc_id = aws_vpc.msa_vpc.id

  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "msa-subnet-a"
  }
}

# Public Subnet C
resource "aws_subnet" "msa_subnet_c" {
  vpc_id     = aws_vpc.msa_vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "msa-subnet-c"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "msa_igw" {
  vpc_id = aws_vpc.msa_vpc.id

  tags = {
    Name = "msa-igw"
  }
}

# Route Table
resource "aws_route_table" "msa_public_rt" {
  vpc_id = aws_vpc.msa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.msa_igw.id
  }

  tags = {
    Name = "msa-public-rt"
  }
}

# Route Table Association - Subnet A
resource "aws_route_table_association" "msa_rt_assoc_a" {
  subnet_id      = aws_subnet.msa_subnet_a.id
  route_table_id = aws_route_table.msa_public_rt.id
}

# Route Table Association - Subnet C
resource "aws_route_table_association" "msa_rt_assoc_c" {
  subnet_id      = aws_subnet.msa_subnet_c.id
  route_table_id = aws_route_table.msa_public_rt.id
}

# Security Group (EC2)
resource "aws_security_group" "msa_sg" {
  name        = "msa-security-group"
  description = "Security group for MSA K3s cluster"
  vpc_id      = aws_vpc.msa_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH - Protected by PEM key + Fail2Ban"
  }

  # K3s API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K3s API Server"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # NodePort range
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K3s NodePort range"
  }

  # Grafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana"
  }

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Prometheus"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "msa-sg"
  }
}

# EC2 Instance
resource "aws_instance" "msa_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id                   = aws_subnet.msa_subnet_a.id
  vpc_security_group_ids      = [aws_security_group.msa_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # 로그 파일 설정
              LOGFILE="/var/log/user-data.log"
              exec > >(tee -a $LOGFILE)
              exec 2>&1
              
              echo "========================================="
              echo "Starting MSA K3s Setup at $(date)"
              echo "========================================="

              # 시스템 업데이트
              echo "[1/6] Updating system packages..."
              apt-get update
              apt-get upgrade -y

              # Fail2Ban 설치 및 설정
              echo "[2/6] Installing and configuring Fail2Ban..."
              apt-get install -y fail2ban
              systemctl enable fail2ban
              systemctl start fail2ban
              echo "Fail2Ban installed and started"

              # Docker 설치
              echo "[3/6] Installing Docker..."
              apt-get install -y docker.io
              systemctl enable docker
              systemctl start docker
              
              # ubuntu 사용자를 docker 그룹에 추가
              usermod -aG docker ubuntu
              echo "Docker installed"

              # K3s 설치 (Traefik 비활성화)
              echo "[4/6] Installing K3s..."
              curl -sfL https://get.k3s.io | sh -s - \
                --write-kubeconfig-mode 644 \
                --disable traefik
              sleep 15
              echo "K3s installed"

              # Helm 설치
              echo "[5/6] Installing Helm..."
              curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
              echo "Helm installed"

              # K8s API 서버(6443)가 외부 IP로 응답하도록 설정
              echo "[6/6] Patching K3s kubeconfig for external access..."
              sed -i "s/127.0.0.1/0.0.0.0/g" /etc/rancher/k3s/k3s.yaml
              systemctl restart k3s

              echo "========================================="
              echo "Setup completed successfully at $(date)"
              echo "========================================="
              EOF

  tags = {
    Name = "msa-k3s-server"
  }
}

# Elastic IP
resource "aws_eip" "msa_eip" {
  instance = aws_instance.msa_server.id
  domain   = "vpc"

  tags = {
    Name = "msa-eip"
  }

  depends_on = [aws_internet_gateway.msa_igw]
}