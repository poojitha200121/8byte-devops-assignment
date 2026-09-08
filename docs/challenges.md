# Challenges and Resolutions

## 1. Working within AWS Free Tier limits

The setup had to stay practical without creating unnecessary cost. EC2-based hosting was used instead of EKS or ECS Fargate, NAT Gateway was avoided, and the monitoring setup was kept lightweight. An Application Load Balancer was added because it was part of the assignment requirement.

## 2. Terraform state management

Local Terraform state is not ideal for repeatable infrastructure work. An S3 backend was created with encryption, versioning, and public access blocking to store state safely.

## 3. Secure CI/CD access to AWS

GitHub Actions uses OIDC with an IAM role instead of long-lived AWS access keys. The workflow receives temporary AWS credentials only when it runs from the expected repository and branch.

## 4. Deployment without SSH

AWS Systems Manager Run Command is used instead of SSH for deployment. The pipeline builds and pushes the Docker image, then SSM runs the deployment commands on EC2.

## 5. Application metrics endpoint

The Prometheus endpoint initially returned `404` because the application did not expose Prometheus metrics by default. Spring Boot Actuator and the Prometheus registry configuration were added, then `/actuator/prometheus` was verified.

## 6. Prometheus and Grafana connectivity

Prometheus and Grafana run as separate Docker containers. The datasource URL and scrape target had to match Docker networking. Both containers were placed on the same Docker network, and Grafana was configured to query Prometheus by container name.

## 7. Centralized logs

Docker local logs are useful for debugging, but centralized logging is easier to operate. The application container sends logs to CloudWatch Logs using the AWS logs driver.

## 8. Runtime configuration after EC2 recreation

When EC2 was recreated, manually created runtime files were lost. Runtime configuration was moved to AWS Secrets Manager. During deployment, EC2 fetches the secret and recreates the env file before starting the container.

## 9. Changing public IP during testing

The local public IP changed during testing, which affected security group access. The allowed CIDR was kept configurable. For production, this should be restricted to office/VPN networks or replaced with a more controlled access pattern.
