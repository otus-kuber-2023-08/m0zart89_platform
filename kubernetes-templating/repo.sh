#!/bin/bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx --namespace=nginx-ingress --create-namespace
sleep 10
export EXTERNAL_IP=$(kubectl get services    --namespace nginx-ingress    nginx-ingress-ingress-nginx-controller    --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
envsubst < ./harbor/values.yaml.tpl > ./harbor/values.yaml
envsubst < ./chartmuseum/values.yaml.tpl > ./chartmuseum/values.yaml
envsubst < ./hipster-shop/values.yaml.tpl > ./hipster-shop/values.yaml
helmfile -f ./helmfile/helmfile.yaml sync
helm registry login harbor.${EXTERNAL_IP}.sslip.io --username admin --password Harbor12345
helm package frontend
helm push frontend-0.1.0.tgz oci://harbor.${EXTERNAL_IP}.sslip.io/library
helm package hipster-shop
helm push hipster-shop-0.1.0.tgz oci://harbor.${EXTERNAL_IP}.sslip.io/library
helm upgrade --install hipster-shop hipster-shop --namespace hipster-shop --create-namespace -f hipster-shop/secrets.yaml
