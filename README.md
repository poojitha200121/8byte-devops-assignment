# 8Byte DevOps Assignment

## Overview

This repository contains my solution for the 8Byte DevOps assignment. The goal was to take a ready-made Java application and build the surrounding DevOps setup for provisioning, deployment, monitoring, logging, and documentation.

I used Spring Petclinic as the sample application because the assignment clearly mentioned that application logic was not the main focus. Most of the effort is therefore around AWS infrastructure, Docker image handling, CI/CD automation, monitoring, and operational practices.

## Tech Stack

- Java 21, Spring Boot
- Docker
- Terraform
- AWS EC2, RDS PostgreSQL, ECR, IAM, SSM, CloudWatch
- GitHub Actions
- Prometheus and Grafana

## Repository Structure

```text
application/                 Spring Petclinic application and Dockerfile
terraform/state-backend/     S3 backend for Terraform state
terraform/infrastructure/    AWS infrastructure code
.github/workflows/           CI/CD pipeline
monitoring/                  Prometheus and Grafana configuration
```

## Infrastructure

Terraform provisions the following AWS resources:

- VPC with public and private subnets
- Internet Gateway and route table
- EC2 instance for running Docker containers
- RDS PostgreSQL database in private subnets
- ECR repository for Docker images
- Application Load Balancer for application access
- Security groups for application and database access
- IAM role and instance profile for EC2
- GitHub Actions OIDC role for CI/CD
- CloudWatch log group

The application is hosted on EC2 using Docker. RDS is kept in private subnets and is reachable only from the application security group. The Application Load Balancer provides the main entry point for the application.

## Deployment Flow

GitHub Actions is used for continuous integration and continuous deployment.

For pull requests, the pipeline runs:

- Repository checkout
- Java 21 setup
- Maven tests
- Docker build validation

For pushes to `main`, the pipeline additionally:

- Authenticates to AWS using OIDC
- Logs in to Amazon ECR
- Builds and tags Docker image with Git commit SHA
- Pushes Docker image to ECR
- Deploys to EC2 using AWS SSM Run Command

There is no need to use SSH for deployment. The EC2 instance is managed through AWS Systems Manager, which keeps the deployment flow cleaner and avoids opening port 22.

## Runtime Configuration

Application runtime configuration is stored on EC2 in:

```text
/opt/petclinic/app.env
```

Example:

```env
SPRING_PROFILES_ACTIVE=postgres
POSTGRES_URL=jdbc:postgresql://<rds-endpoint>:5432/petclinic
POSTGRES_USER=petclinicadmin
POSTGRES_PASS=<database-password>
```

This file is intentionally not committed to Git because it contains environment-specific values and secrets.

## Monitoring and Logging

Prometheus scrapes Spring Boot Actuator metrics from:

```text
/actuator/prometheus
```

Grafana is used for creating dashboards.

Dashboards include:

- Application metrics: JVM memory, CPU usage, HTTP request metrics
- Infrastructure metrics: service availability, scrape duration, process metrics

CloudWatch Logs is used for centralized application logging, and log retention is configured through Terraform.

## Security Considerations

Security practices followed:

- RDS is deployed in private subnets
- Database access is allowed only from the application security group
- Application traffic is routed through an Application Load Balancer
- GitHub Actions uses OIDC instead of long-lived AWS keys
- EC2 access and deployment use AWS SSM instead of SSH
- Sensitive files like terraform.tfvars are not included in Git
- Application secrets are stored outside the repository
- Security group ingress is configurable

For demo purposes, some access rules can be temporarily opened. In a real production setup, I would restrict access further using office/VPN CIDR ranges, private subnets for the application layer, WAF rules, and a stricter ALB-only traffic path.

## Cost Considerations

The setup was created with an AWS Free Tier account in mind, so I avoided expensive components wherever possible.

Cost-saving choices:

- Single EC2 instance
- No NAT Gateway
- Minimal ALB usage for the assignment requirement
- Minimal monitoring setup
- Small RDS instance

For a larger production setup, I would add Auto Scaling, Multi-AZ RDS, private application subnets, VPC endpoints, AWS Secrets Manager or SSM Parameter Store, and stronger alerting.

## Useful Commands

Terraform state backend:

```bash
terraform -chdir=terraform/state-backend init
terraform -chdir=terraform/state-backend apply
```

Infrastructure:

```bash
terraform -chdir=terraform/infrastructure init
terraform -chdir=terraform/infrastructure plan
terraform -chdir=terraform/infrastructure apply
```

Docker build:

```bash
docker build -t petclinic:test application
```

Cleanup:

```bash
terraform -chdir=terraform/infrastructure destroy
```

## Demo URLs

Application through Load Balancer:

```text
http://8byte-staging-alb-885064939.ap-south-1.elb.amazonaws.com
```

Direct EC2 application URL:

```text
http://13.232.100.65:9090
```

Grafana:

```text
http://13.232.100.65:3000
```
