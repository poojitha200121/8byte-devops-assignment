# Architecture

This project deploys a Dockerized Spring Boot Petclinic application on AWS. Terraform creates the infrastructure, GitHub Actions builds and deploys the application, and monitoring/logging is handled using Prometheus, Grafana, and CloudWatch.

## High-Level Flow

```mermaid
flowchart TB
    user["User / Browser"]
    github["GitHub Repository"]
    actions["GitHub Actions"]
    oidc["GitHub OIDC"]
    iam["AWS IAM Role"]
    ecr["Amazon ECR"]
    ssm["AWS Systems Manager"]
    state["S3 Terraform State Backend"]

    subgraph aws["AWS ap-south-1"]
        subgraph vpc["VPC"]
            subgraph public["Public Subnets"]
                alb["Application Load Balancer"]
                ec2["EC2 Instance"]
                app["Petclinic Docker Container<br/>Host 9090 -> Container 8080"]
                prometheus["Prometheus<br/>Host 9091"]
                grafana["Grafana<br/>Host 3000"]
            end

            subgraph private["Private Subnets"]
                rds["RDS PostgreSQL<br/>Port 5432"]
            end
        end

        cloudwatch["CloudWatch Logs"]
        parameter["SSM Parameter Store<br/>SecureString"]
    end

    user -->|"HTTP"| alb
    alb -->|"Forward traffic"| app
    app -->|"Database connection"| rds

    github --> actions
    actions -->|"OIDC authentication"| oidc
    oidc --> iam
    actions -->|"Build and push image"| ecr
    actions -->|"Send deploy command"| ssm
    ssm --> ec2
    ec2 -->|"Pull image"| ecr
    ec2 -->|"Fetch runtime env"| parameter
    ec2 --> app

    prometheus -->|"Scrape /actuator/prometheus"| app
    grafana -->|"Read metrics"| prometheus
    app -->|"Application logs"| cloudwatch
    state -->|"Stores Terraform state"| aws
```

## Simplified Flow Diagrams

The full diagram above shows all major components together. The smaller diagrams below split the same architecture into runtime, deployment, and monitoring/logging flows.

### Application Runtime Flow

```mermaid
flowchart LR
    user["User / Browser"] --> alb["Application Load Balancer"]
    alb --> ec2["EC2 Instance"]
    ec2 --> app["Petclinic Docker Container<br/>Host 9090 -> Container 8080"]
    app --> rds["RDS PostgreSQL<br/>Private Subnet"]
```

### CI/CD Deployment Flow

```mermaid
flowchart LR
    dev["Code push to main"] --> gha["GitHub Actions"]
    gha --> test["Run tests<br/>Build Docker image"]
    test --> ecr["Push image to ECR"]
    gha --> ssm["AWS SSM Run Command"]
    ssm --> ec2["EC2 Instance"]
    ec2 --> app["Run updated container"]
```

### Monitoring and Logging Flow

```mermaid
flowchart LR
    app["Petclinic App<br/>/actuator/prometheus"] --> prometheus["Prometheus"]
    prometheus --> grafana["Grafana Dashboard"]

    app --> dockerlogs["Docker Logs"]
    dockerlogs --> cloudwatch["CloudWatch Logs"]
```

## Flow Summary

- Users access the application through the Application Load Balancer.
- The ALB forwards traffic to the EC2 instance on port `9090`.
- Docker maps EC2 port `9090` to container port `8080`.
- The application connects to RDS PostgreSQL in private subnets.
- GitHub Actions builds the Docker image and pushes it to ECR.
- Deployment is done through AWS SSM Run Command.
- Runtime configuration is stored in SSM Parameter Store as a `SecureString`.
- Prometheus collects application metrics from `/actuator/prometheus`.
- Grafana reads metrics from Prometheus.
- Application logs are sent to CloudWatch Logs using Docker's `awslogs` driver.
- Terraform state is stored in S3.

## Design Notes

- The setup is intentionally lightweight for assignment and demo use.
- EC2 is used for simple container hosting.
- RDS is kept private for better security.
- SSM is used instead of SSH for deployment.
- In production, EC2 can be moved fully behind the ALB, HTTPS can be added, and Auto Scaling or ECS can be used.
