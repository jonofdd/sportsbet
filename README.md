# sportsbet
Repo for sportsbet task assignment 


Steps to achieve end goal

A terraform user has been manually added via IAM and made a member of an appropriate group to achieve the necessary permissions to create and manipulate resources. An access key is then generated and loaded in the environment so that terraform can authenticate to perform the needed actions.

An s3 bucket is manually created so that the Terraform code may use it to store the tfstate file in a remote backend.

The ECR is created manually, and an appopriate image is uploaded that may later be used for by ECS.

The terraform code is then created to achieve following:

I've configured a virtual private cloud (VPC) with a CIDR block "10.0.0.0/16". This VPC acts as a virtual network isolated from other networks in AWS, providing a controlled space where AWS resources can be launched.

I've attached an internet gateway to the VPC, enabling communication between the resources inside the VPC and the internet. This is necessary for accessing the internet and for providing public internet access to services running in the VPC.

Route tables are set up to define rules for traffic routing within the VPC. Specifically, I've configured a route that directs all outbound traffic (0.0.0.0/0) to the internet gateway, allowing resources in the VPC to access the internet. I've also associated this route table with two subnets.

Two subnets (subnet1 and subnet2) are defined within the VPC, each in a different availability zone (eu-west-1a and eu-west-1b). This setup enhances the availability and fault tolerance of the application by distributing the workload across multiple data centers.

An ALB named "sportsbet-alb" is configured to distribute incoming traffic across multiple targets, such as EC2 instances or containers, in multiple availability zones. This improves the application's fault tolerance and performance.

An S3 bucket is provisioned to store logs, particularly from the ALB. This allows for centralized storage and analysis of access logs which can be crucial for troubleshooting and understanding traffic patterns.

I've set up policies to control access to the S3 bucket, allowing specific AWS services and accounts to interact with the stored logs.

These include a log group for capturing logs from the application and a CloudWatch dashboard configured to monitor metrics such as CPU and memory utilization from ECS and HTTP response codes from the ALB.

Security Groups: Security groups act as virtual firewalls, controlling the inbound and outbound traffic to resources like the ALB and other services. I've configured them to allow HTTP (port 80) and HTTPS (port 443) traffic.

These include an ECS cluster, a task definition, and an ECS service. The ECS cluster provides the infrastructure for the containerized application. The task definition specifies how the containers should run (e.g., which Docker image to use, CPU and memory allocations). The ECS service manages the running containers, ensuring the desired number of instances are always running and are registered with the load balancer.

Finally, I've declared an output for the DNS name of the ALB, which can be used to access the application once everything is deployed.