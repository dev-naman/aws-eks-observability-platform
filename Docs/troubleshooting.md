# Troubleshooting Guide

This document captures the issues encountered while building and deploying the AWS EKS Landing Zone using Terraform, Kubernetes, Helm, Prometheus, Grafana, NGINX, and AWS Load Balancer Controller.

---

# Issue 1: EKS Node Group Creation Failed

## Error

```bash
Error: creating EKS Node Group

InvalidRequestException:
You are not authorized to launch instances with this launch template.
```

## Root Cause

The IAM user or role creating the EKS managed node group did not have sufficient permissions to launch EC2 instances using the generated launch template.

Additionally, the organization's IAM policies contained restrictions on allowed EC2 instance types.

## Verification

Check attached policies:

```bash
aws iam list-attached-role-policies \
  --role-name dev-eks-node-role
```

Check organization IAM policies:

```bash
aws iam get-group-policy \
  --group-name <GROUP_NAME> \
  --policy-name <POLICY_NAME>
```

## Resolution

Use an approved instance type allowed by organizational policies.

Example:

```hcl
instance_types = ["t2.medium"]
```

Re-run Terraform:

```bash
terraform apply
```

---

# Issue 2: kubectl Authentication Failed

## Error

```bash
error: You must be logged in to the server
(the server has asked for the client to provide credentials)
```

## Root Cause

The IAM user was not added to the EKS access configuration.

EKS authentication succeeded, but authorization failed.

## Verification

Check current AWS identity:

```bash
aws sts get-caller-identity
```

Check EKS access entries:

```bash
aws eks list-access-entries \
  --cluster-name dev-demo-eks \
  --region us-east-1
```

Output:

```json
{
  "accessEntries": [
    "arn:aws:iam::<ACCOUNT_ID>:role/dev-eks-node-role"
  ]
}
```

User entry was missing.

## Resolution

Create access entry:

```bash
aws eks create-access-entry \
  --cluster-name dev-demo-eks \
  --principal-arn arn:aws:iam::<ACCOUNT_ID>:user/<USERNAME>
```

Associate admin permissions:

```bash
aws eks associate-access-policy \
  --cluster-name dev-demo-eks \
  --principal-arn arn:aws:iam::<ACCOUNT_ID>:user/<USERNAME> \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

Update kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name dev-demo-eks
```

Verify:

```bash
kubectl get nodes
```

---

# Issue 3: Node Not Ready

## Error

```bash
Ready False

KubeletNotReady

container runtime network not ready:
cni plugin not initialized
```

## Root Cause

Amazon VPC CNI plugin was not installed.

Without the CNI plugin, pods cannot obtain IP addresses.

## Verification

Check addons:

```bash
aws eks list-addons \
  --cluster-name dev-demo-eks
```

Output:

```json
{
  "addons": []
}
```

No networking addon was present.

## Resolution

Install VPC CNI addon:

```bash
aws eks create-addon \
  --cluster-name dev-demo-eks \
  --addon-name vpc-cni
```

Install CoreDNS:

```bash
aws eks create-addon \
  --cluster-name dev-demo-eks \
  --addon-name coredns
```

Install kube-proxy:

```bash
aws eks create-addon \
  --cluster-name dev-demo-eks \
  --addon-name kube-proxy
```

Verify:

```bash
kubectl get nodes
```

Expected:

```bash
STATUS   ROLES    AGE   VERSION
Ready    <none>   XXm   v1.xx
```

---

# Issue 4: Grafana Not Reachable

## Symptom

Grafana service existed but browser could not access it.

## Verification

Check service:

```bash
kubectl get svc
```

Output:

```bash
monitoring-grafana   ClusterIP
```

## Root Cause

ClusterIP services are only accessible inside the cluster.

## Resolution

Expose Grafana as LoadBalancer:

```bash
kubectl patch svc monitoring-grafana \
  -p '{"spec":{"type":"LoadBalancer"}}'
```

Verify:

```bash
kubectl get svc monitoring-grafana
```

Expected:

```bash
EXTERNAL-IP
xxxxxxxx.us-east-1.elb.amazonaws.com
```

Access:

```text
http://<LOAD_BALANCER_DNS>
```

---


# Useful Verification Commands

## Cluster

```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A
```

## Terraform

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
```

## AWS

```bash
aws sts get-caller-identity

aws eks describe-cluster \
  --name dev-demo-eks

aws eks list-nodegroups \
  --cluster-name dev-demo-eks

aws eks list-access-entries \
  --cluster-name dev-demo-eks
```

## Helm

```bash
helm list -A

helm repo update

helm upgrade --install
```

---

# Final Working Architecture

```text
Internet
    |
    v
+-----------------------+
| AWS Application LB    |
+-----------------------+
          |
          |
+-----------------------------------+
| Kubernetes Ingress                |
+-----------------------------------+
     |       |         |         |
     |       |         |         |
     v       v         v         v

   /       /grafana  /argocd  /jenkins

 NGINX     Grafana    ArgoCD   Jenkins
```

---

# Lessons Learned

- Always install EKS core addons (VPC CNI, CoreDNS, kube-proxy).
- Verify IAM permissions before creating node groups.
- Use EKS Access Entries for cluster authentication.
- Prefer ALB Ingress over multiple LoadBalancer services.
- Store Terraform state remotely in S3.
- Use DynamoDB locking for Terraform state protection.
- Maintain architecture diagrams and troubleshooting documentation for production-grade repositories.