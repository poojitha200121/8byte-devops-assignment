# 8Byte DevOps Assignment

## Overview

The project shows how a Java Spring Boot application can be deployed on AWS using Terraform, Docker, GitHub Actions, Amazon ECR, EC2, RDS PostgreSQL, Prometheus, Grafana, and CloudWatch Logs.

The application in question is Spring Petclinic; although the application logic is not the main concern, emphasis is placed on infrastructure provisioning, deployment automation, monitoring, logging, and following security best practices.

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
- Security groups for application and database access
- IAM role and instance profile for EC2
- GitHub Actions OIDC role for CI/CD
- CloudWatch log group

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

There is no need to use SSH for deployment.

## Runtime Configuration

Application runtime secrets are stored on EC2 in:

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

The file has not been committed to Git.

## Monitoring and Logging

Prometheus scrapes Spring Boot Actuator metrics from:

```text
/actuator/prometheus
```

Grafana is used for creating dashboards.

Dashboards include:

- Application metrics: JVM memory, CPU usage, HTTP request metrics
- Infrastructure metrics: service availability, scrape duration, process metrics

CloudWatch Logs is used for centralised logging, and log retention is set up using Terraform.

## Security Considerations

Security practices followed:

- RDS is deployed in private subnets
- Database access is allowed only from the application security group
- GitHub Actions uses OIDC instead of long-lived AWS keys
- EC2 access and deployment use AWS SSM instead of SSH
- Sensitive files like terraform.tfvars are not included in Git
- Application secrets are stored outside the repository
- Security group ingress is configurable

To obtain demo access, the ports can be temporarily opened with the use of `0.0.0.0/0`. In a production environment, however, access should be restricted by means of a VPN, by the office IP ranges, by the load balancer rules, or by using a WAF.

## Cost Considerations

The setup was created with an AWS Free Tier account in mind.

Cost-saving choices:

- Single EC2 instance
- No NAT Gateway
- No Application Load Balancer
- Minimal monitoring setup
- Small RDS instance

To improve this in terms of production, you could use Auto Scaling, a Load Balancer, Multi-AZ RDS, private application subnets, VPC endpoints, and AWS Secrets Manager or the SSM Parameter Store.

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

Application:

```text
http://13.232.100.65:9090
```

Grafana:

```text
http://13.232.100.65:3000

```