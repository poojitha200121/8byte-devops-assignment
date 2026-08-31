# Challenges and Resolutions

## 1. Working within AWS Free Tier limits

The main constraint was to keep the solution practical without creating unnecessary cost. I chose EC2-based hosting instead of EKS or ECS Fargate, avoided NAT Gateway, and kept the monitoring setup lightweight. An Application Load Balancer was added because it was part of the assignment requirement, but the rest of the architecture was kept minimal.

## 2. Terraform state management

Local Terraform state is not ideal once a project becomes collaborative or needs repeatable deployment. To handle this better, I created an S3 backend with encryption, versioning, and public access blocking. This gives a safer place to store the infrastructure state.

## 3. Secure CI/CD access to AWS

I wanted the pipeline to deploy without storing long-lived AWS access keys in GitHub. I used GitHub Actions OIDC with an IAM role, so the workflow can request temporary AWS credentials only when it runs from the expected repository and branch.

## 4. Deployment without SSH

Opening SSH access just for deployment adds unnecessary exposure. I used AWS Systems Manager Run Command to connect the GitHub Actions workflow to the EC2 instance. The pipeline builds and pushes the Docker image, then SSM runs the deployment command on the instance.

## 5. Application metrics endpoint

The Prometheus endpoint initially returned a 404 because the application did not expose Prometheus metrics by default. I added the required Spring Boot Actuator and Prometheus registry configuration, rebuilt the Docker image, and verified that `/actuator/prometheus` returned metrics.

## 6. Prometheus and Grafana connectivity

Prometheus and Grafana were running as separate Docker containers, so the datasource URL and scrape target had to match Docker networking correctly. After placing the containers on the same Docker network and fixing the target port, Grafana was able to query Prometheus.

## 7. Centralized logs

Docker logs are easy to check locally, but they are not enough for centralized logging. I configured the application container to send logs to CloudWatch Logs using the AWS logs driver. This makes application logs available from the AWS Console.

## 8. Changing public IP during testing

My local internet public IP changed while testing security group access. To keep the setup flexible, I made the allowed CIDR configurable. For a production setup, this should be restricted to office/VPN networks or replaced with a more controlled access pattern.
