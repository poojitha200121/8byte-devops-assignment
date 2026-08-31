#!/bin/bash

set -e

yum update -y

yum install -y docker

systemctl start docker

systemctl enable docker

usermod -aG docker ec2-user

systemctl status docker --no-pager

docker --version 

echo "Docker installation completed"
