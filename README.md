# MSA Playground Infra

MSA Playground용 AWS 인프라를 Terraform으로 관리하는 레포지토리입니다.  
Terraform 코드를 통해 VPC, Subnet, IAM 등 기본 인프라를 배포합니다.

## 구조
- `main.tf` : 주요 리소스 정의
- `variables.tf` : 변수 정의
- `outputs.tf` : 출력 값 정의
- `terraform.tfvars` : (민감 정보 포함, .gitignore 처리)

## 배포
```bash
# 초기화
terraform init

# 계획 확인
terraform plan -var-file="terraform.tfvars"

# 적용
terraform apply -var-file="terraform.tfvars"
```

## terraform.tfvars.example
```tfvars
aws_region    = "ap-northeast-2"
instance_type = "t3.micro"
key_name        = "example-key"
```
