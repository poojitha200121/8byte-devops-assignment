#. Resolutions

## 1. AWS Free Tier Constraints

Challenge: AWS Free Tier Constraints required keeping infrastructure cost low.

Resolution: AWS Free Tier Constraints were handled by using EC2 of EKS or ECS Fargate avoiding NAT Gateway and ALB and keeping RDS and monitoring minimal.

## 2. Terraform State Management

Challenge: Terraform State Management was not ideal for team or project workflows.

Resolution: Terraform State Management was solved by creating an S3 backend that uses encryption and versioning.

## 3. Secure CI/CD AWS Access

Challenge: Secure CI/CD AWS Access involved avoiding the storage of AWS access keys, in GitHub.

Resolution: Secure CI/CD AWS Access was managed by using GitHub Actions OIDC with an IAM role.

## 4. Deployment Without SSH

Challenge: Deployment Without SSH required a method that did not open an SSH tunnel.

Resolution: Deployment Without SSH was achieved by using AWS SSM Run Command to pull the code and restart the Docker container.

## 5. Monitoring Endpoint Issue

Challenge: Monitoring Endpoint Issue was that `/actuator/prometheus` returned a 404 error at first.

Resolution: Monitoring Endpoint Issue was fixed by adding the Micrometer Prometheus registry dependency and rebuilding the Docker image.

## 6. Dynamic Public IP

Challenge: Dynamic Public IP occurred when the laptop public IP changed during testing.

Resolution: Dynamic Public IP was handled by making the CIDR configurable using temporary demo access and recommending that production restrict access.