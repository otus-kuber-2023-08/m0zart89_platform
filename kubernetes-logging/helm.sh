#!/bin/bash
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx --namespace=nginx-ingress --create-namespace -f nginx-ingress.values.yaml
export EXTERNAL_IP=$(kubectl get services --namespace nginx-ingress nginx-ingress-ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
wget https://github.com/elastic/helm-charts/archive/refs/tags/v7.17.3.tar.gz -O v7.17.3.tar.gz
tar -xzf v7.17.3.tar.gz
helm upgrade --install elasticsearch ./helm-charts-7.17.3/elasticsearch -n observability -f elasticsearch.values.yaml
helm repo add fluent https://fluent.github.io/helm-charts
helm upgrade --install fluent-bit fluent/fluent-bit --version 0.39.0 --namespace observability -f fluentbit.values.yaml
helm upgrade --install kibana ./helm-charts-7.17.3/kibana -n observability -f kibana.values.yaml
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace observability -f kube-prometheus-stack.values.yaml
helm upgrade --install prometheus-elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter --namespace observability -f prometheus-elasticsearch-exporter.values.yaml
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install loki grafana/loki-stack -n observability -f loki.values.yaml
