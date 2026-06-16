# Deployment Guide

## Clone Repository

git clone https://github.com/dev-naman/aws-eks-observability-platform.git

## Initialize Terraform

terraform init

## Validate

terraform validate

## Plan

terraform plan

## Deploy

terraform apply

## Configure kubectl

aws eks update-kubeconfig \
--region us-east-1 \
--name dev-demo-eks

## Verify Cluster

kubectl get nodes