# variable "ecr_repo_name" {
#   description = "Sportsbet ECR"
#   type        = string
#   default     = "sportsbet-ecr-repo"
# }

# variable "certificate_arn" {
#   description = "Certificate arn"
#   type = string
#   default = "arn:aws:acm:eu-west-1:730335593632:certificate/15f3a771-b110-4420-9124-a6688dc59fbd"
# }

variable "image_name" {
  description = "Docker image"
  type        = string
  default     = "sportsbet"
}

variable "ecr_repo_tags" {
  description = "Tags to assign to ECR"
  type        = map(string)
  default = {
    Environment = "Dev"
    App         = "Webapp"
  }
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "aws_vpc.sportsbet_vpc.id"
}

# variable "subnet_ids" {
#   description = "List of subnet IDs"
#   type        = list(string)
# }

variable "security_group_id" {
  description = "List of security group IDs"
  type        = list(string)
  default     = ["sportsbet_sg_1", "sportsbet_sg_2"]
}