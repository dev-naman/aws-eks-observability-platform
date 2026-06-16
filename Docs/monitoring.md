# Monitoring Setup

## Install Prometheus Stack

helm repo add prometheus-community \
https://prometheus-community.github.io/helm-charts

helm repo update

helm install monitoring \
prometheus-community/kube-prometheus-stack

## Verify

kubectl get pods

## Access Grafana

kubectl get svc

Open Grafana Load Balancer URL.