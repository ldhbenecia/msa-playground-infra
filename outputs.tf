output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.msa_vpc.id
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.msa_server.id
}

output "ec2_public_ip" {
  description = "EC2 Public IP (Elastic IP)"
  value       = aws_eip.msa_eip.public_ip
}

output "ec2_public_dns" {
  description = "EC2 Public DNS"
  value       = aws_instance.msa_server.public_dns
}

output "ssh_command" {
  description = "SSH Connection Command"
  value       = "ssh -i ~/.ssh/msa-key.pem ubuntu@${aws_eip.msa_eip.public_ip}"
}

output "kubeconfig_command" {
  description = "Copy kubeconfig from server"
  value       = "scp -i ~/.ssh/msa-key.pem ubuntu@${aws_eip.msa_eip.public_ip}:/etc/rancher/k3s/k3s.yaml ~/.kube/config-k3s"
}

output "setup_status_command" {
  description = "Check setup status"
  value       = "ssh -i ~/.ssh/msa-key.pem ubuntu@${aws_eip.msa_eip.public_ip} 'cat ~/setup-status.txt'"
}

output "fail2ban_status_command" {
  description = "Check Fail2Ban status"
  value       = "ssh -i ~/.ssh/msa-key.pem ubuntu@${aws_eip.msa_eip.public_ip} 'sudo fail2ban-client status'"
}