terraform {
  backend "s3" {
    bucket = "terraform-bucket-sportsbet-task"
    key    = "terraform.tfstate"
    region = "eu-west-1" # Change this to your desired AWS region
  }
}