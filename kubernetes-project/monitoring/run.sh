#!/bin/bash
helm upgrade  --namespace monitoring demo \
 -f alertmanager/values.yaml \
 -f grafana/values.yaml \
 -f prometheus/values.yaml \
 -f ./grafana/secrets.yaml \
 --install --create-namespace \
 prometheus-community/kube-prometheus-stack
