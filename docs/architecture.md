# Architecture Diagram

This diagram shows the high-level flow of the deployed DevOps assignment.

```mermaid
flowchart TB
    user["User / Browser"]
    github["GitHub Repository"]
    actions["GitHub Actions CI/CD"]
    oidc["GitHub OIDC"]
    iam["AWS IAM Role"]
    ecr["Amazon ECR<br/>Docker Image Registry"]
    ssm["AWS Systems Manager<br/>Run Command"]
    igw["Internet Gateway"]

    subgraph aws["AWS - ap-south-1"]
        subgraph vpc["VPC"]
            subgraph public["Public Subnets"]
                alb["Application Load Balancer<br/>HTTP :80"]
                ec2["EC2 Instance<br/>Amazon Linux 2023"]
                docker["Docker Runtime"]
                app["Spring Petclinic Container<br/>EC2 :9090 -> Container :8080"]
                prometheus["Prometheus Container<br/>EC2 :9091"]
                grafana["Grafana Container<br/>EC2 :3000"]
            end

            subgraph private["Private Subnets"]
                rds["Amazon RDS PostgreSQL<br/>Port :5432"]
            end
        end

        cloudwatch["CloudWatch Logs"]
        state["S3 Terraform State Backend<br/>Encryption + Versioning"]
    end

    user -->|"HTTP request"| igw
    igw --> alb
    alb -->|"Forward to target group"| app
    app -->|"Database connection"| rds

    github --> actions
    actions -->|"Request OIDC token"| oidc
    oidc -->|"Assume role"| iam
    actions -->|"Build and push image"| ecr
    actions -->|"Send deployment command"| ssm
    ssm -->|"Execute Docker commands"| ec2
    ec2 --> docker
    docker --> app
    ec2 -->|"Pull image"| ecr

    prometheus -->|"Scrape /actuator/prometheus"| app
    grafana -->|"Query metrics"| prometheus
    app -->|"Application logs"| cloudwatch
```

## Explanation

- Users access the application through the internet-facing Application Load Balancer.
- The Internet Gateway gives public subnets internet connectivity.
- The ALB listens on port 80 and forwards traffic to the application running on EC2 port 9090.
- Docker maps EC2 port 9090 to the Spring Boot container port 8080.
- RDS PostgreSQL is placed in private subnets and accepts traffic only from the application layer.
- GitHub Actions builds the Docker image and pushes it to Amazon ECR.
- GitHub Actions uses OIDC to assume an AWS IAM role instead of storing AWS access keys.
- Deployment is done through AWS Systems Manager Run Command instead of SSH.
- Prometheus scrapes application metrics from `/actuator/prometheus`.
- Grafana visualizes the metrics collected by Prometheus.
- Application logs are sent to CloudWatch Logs.
- Terraform state is stored remotely in S3 with encryption and versioning.

## Interview Summary

The application entry path is:

```text
User -> Internet Gateway -> ALB:80 -> EC2:9090 -> Docker container:8080
```

The deployment path is:

```text
GitHub Actions -> OIDC/IAM -> ECR -> SSM -> EC2 Docker container
```

The monitoring and logging path is:

```text
Application metrics -> Prometheus -> Grafana
Application logs -> CloudWatch Logs
```
