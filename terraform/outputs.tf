output "vpc_id" {
  value = aws_vpc.bedrock_vpc.id
}

output "public_subnets" {
  value = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}

output "private_subnets" {
  value = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]
}
output "cluster_name" {
  value = aws_eks_cluster.bedrock.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.bedrock.endpoint
}

output "region" {
  value = var.region
}

output "assets_bucket_name" {
  value = aws_s3_bucket.assets.bucket
}
output "bedrock_dev_access_key" {
  description = "Access Key ID for bedrock-dev-view user"
  value       = aws_iam_access_key.bedrock_dev_key.id
}

output "bedrock_dev_secret_key" {
  description = "Secret Access Key for bedrock-dev-view user"
  value       = aws_iam_access_key.bedrock_dev_key.secret
  sensitive   = true
}
