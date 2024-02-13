#!/bin/bash
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx --namespace=nginx-ingress --create-namespace -f nginx-ingress.values.yaml
helm upgrade --install elasticsearch ./helm-charts-8.5.1/elasticsearch -n logging --create-namespace -f elasticsearch.values.yaml
helm upgrade --install kibana ./helm-charts-8.5.1/kibana -n logging --create-namespace -f kibana.values.yaml
helm upgrade --install fluent-bit fluent/fluent-bit -n logging -f fluent-bit.values.yaml --version 0.39.0
