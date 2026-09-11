# 8Byte DevOps Assignment

## Overview

This repository contains an end-to-end DevOps setup for a Spring Boot Petclinic application. The application is containerized with Docker, deployed on AWS, automated with GitHub Actions, and monitored using Prometheus, Grafana, and CloudWatch.

## Tech Stack

- Java 21 and Spring Boot
- Docker
- Terraform
- AWS EC2, RDS PostgreSQL, ECR, IAM, SSM, ALB, CloudWatch, S3, Secrets Manager
- GitHub Actions
- Prometheus and Grafana

## Repository Structure

```text
application/                 Spring Boot application and Dockerfile
terraform/state-backend/     Terraform state backend setup
terraform/infrastructure/    Main AWS infrastructure code
.github/workflows/           CI/CD pipeline
monitoring/                  Prometheus and Grafana setup
docs/                        Architecture and challenge notes
```

## Infrastructure

Terraform provisions the AWS infrastructure required to run the application:

- VPC with public and private subnets
- Internet Gateway and route tables
- EC2 instance for running Docker containers
- RDS PostgreSQL database in private subnets
- Application Load Balancer for application traffic
- ECR repository for Docker images
- Security groups for ALB, application, and database access
- IAM roles for EC2 and GitHub Actions
- CloudWatch log group for application logs
- S3 backend for Terraform state

RDS is not publicly accessible. The application connects to the database from inside the VPC.

## Terraform State

Terraform state is stored in an S3 bucket instead of only on the local machine. The backend bucket is configured with encryption, versioning, and public access blocking.

State backend setup:

```bash
terraform -chdir=terraform/state-backend init
terraform -chdir=terraform/state-backend apply
```

Main infrastructure setup:

```bash
terraform -chdir=terraform/infrastructure init
terraform -chdir=terraform/infrastructure plan
terraform -chdir=terraform/infrastructure apply
```

To destroy the main infrastructure:

```bash
terraform -chdir=terraform/infrastructure destroy
```

The state backend should not be destroyed unless the project is fully cleaned up.

## Deployment

GitHub Actions is used for CI/CD.

On pull requests, the pipeline:

- Checks out the repository
- Sets up Java 21
- Runs Maven tests
- Validates Docker image build

On push to `main`, the pipeline:

- Authenticates to AWS using GitHub OIDC
- Logs in to Amazon ECR
- Builds the Docker image
- Tags the image using the Git commit SHA
- Pushes the image to ECR
- Finds the current EC2 instance by tag
- Deploys the container using AWS SSM Run Command

Deployment is done through AWS Systems Manager instead of SSH, so port 22 does not need to be opened for deployment.

## Runtime Configuration and Secrets

Application runtime configuration is stored in AWS Secrets Manager. Terraform creates the secret resource, and the actual secret value is added separately so passwords are not written in Terraform code.

Secret name:

```text
8byte-devops-assignment/staging/app-env
```

During deployment, the EC2 instance fetches this secret and creates:

```text
/opt/petclinic/app.env
```

The Docker container uses this file through `--env-file`.

This avoids storing database credentials in Git and removes the need to manually recreate the env file when EC2 is replaced.

## Monitoring

Prometheus scrapes application metrics from the Spring Boot Actuator endpoint:

```text
/actuator/prometheus
```

Grafana is used to visualize metrics from Prometheus.

The monitoring setup script is available at:

```text
monitoring/install-monitoring.sh
```

The GitHub Actions deployment job automatically sends this script to EC2 using
SSM and executes it after the application deployment step. No repository checkout
is required on EC2. The job waits for the SSM command and fails if installation or
the Prometheus/Grafana HTTP readiness checks fail.

Each deployment recreates the monitoring containers, briefly interrupting monitoring.
Grafana and Prometheus retain their data in the `grafana-storage` and
`prometheus-storage` Docker volumes on the same EC2 instance. Replacing EC2 requires
a new deployment to install monitoring; these local volumes do not survive instance
replacement. On the first run after this change, any old Prometheus data stored only
inside its container is not migrated into the new volume.

For manual installation or troubleshooting, copy the script to EC2 and run:

```bash
sudo bash monitoring/install-monitoring.sh
```

Useful monitoring URLs:

```text
Prometheus: http://<EC2_PUBLIC_IP>:9091
Grafana:    http://<EC2_PUBLIC_IP>:3000
```

Example dashboard areas:

- Application availability
- HTTP request count
- Request latency
- JVM memory usage
- JVM threads
- Database connection pool metrics

## Logging

Application logs are centralized in CloudWatch Logs. The application container uses Docker's `awslogs` log driver and sends logs to:

```text
8byte-devops-assignment-staging-application-logs
```

CloudWatch log retention is configured in Terraform to control cost.

## Security Considerations

- RDS PostgreSQL is deployed in private subnets.
- Database access is allowed only from the application security group.
- GitHub Actions uses OIDC instead of long-lived AWS access keys.
- EC2 uses an IAM instance profile for AWS access.
- Deployment is done using SSM instead of SSH.
- Runtime secrets are stored in AWS Secrets Manager.
- EC2 metadata uses IMDSv2.
- ECR image scanning is enabled.
- Security group ingress is configurable using Terraform variables.

## Backup Strategy

RDS automated backup retention is configured in Terraform:

```hcl
backup_retention_period = 1
```

For this assignment, the retention period is kept low to reduce cost. For production, backup retention should be increased, deletion protection should be enabled, and final snapshots should be retained.

## Cost Optimization

The setup is kept lightweight to control AWS cost:

- Single EC2 instance
- Small RDS instance
- Single-AZ RDS
- No NAT Gateway
- Short CloudWatch log retention
- Short RDS backup retention
- Resources can be destroyed using Terraform after testing

## Useful Checks

Check Terraform outputs:

```bash
terraform -chdir=terraform/infrastructure output
```

Check application container:

```bash
docker ps
curl -I http://localhost:9090/
curl -I http://localhost:9090/actuator/health
```

Check Docker log driver:

```bash
docker inspect petclinic --format '{{.HostConfig.LogConfig.Type}}'
```

Expected log driver:

```text
awslogs
```

Check Prometheus targets:

```text
http://<EC2_PUBLIC_IP>:9091/targets
```

## Access URLs

Use Terraform outputs to get the current ALB DNS name, EC2 public IP, ECR repository URL, and database endpoint:

```bash
terraform -chdir=terraform/infrastructure output
```
