# Курсовая работа

## Тема

Инфраструктурная managed k8s платформа для онлайн магазина microservices-demo

## Содержание

1. Описание
2. IaC
3. CI/CD
3. Monitoring
4. Logging

## 1. Описание

Платформа состоит из репозитория проекта, репозитория клиентского приложения и кластера в Yandex Cloud.
Развёртывание производится с помощью Terraform.
CI строится на Gitlab и ArgoCD.
Мониторинг на основе Prometheus/Grafana.
Логирование на основе EFK Stack.

## 2. IaC

Для разворачивания кластера перейти в директорию iac, создать файл `auth.json` с содержимым:
```shell
{
   "id": "aje...",
   "service_account_id": "aje...",
   "created_at": "202...",
   "key_algorithm": "RSA_2048",
   "public_key": "-----BEGIN PUB...",
   "private_key": "-----BEGIN PRI"
}
```

Развернуть кластер командой `terraform apply -auto-approve`

По окончанию операции (займёт ~7 минут) кластер пропишется в контекст как основной

## 3. IaC

Для настройки IaC перейти в папку cicd и выполнить команды:

```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
kubectl apply -f argocd_ingress_rule.yaml -n argocd
kubectl apply -f frontend_ingress_rule.yaml -n argocd
kubectl apply -f app.yaml -n argocd
```

Для проверки IaC необходимо сделать коммит исходный код образов контейнеров или helm-чарты репозитория клиентского приложения https://gitlab.com/m0zart89/microservices-demo

По окончанию build заменится текущий образ последним (digest).

## 4. Monitoring

Для настройки мониторинга перейти в папку monitoring, исправить адреса хостов и выполнить команды:
```shell
helm upgrade  --namespace monitoring demo \
 -f alertmanager/values.yaml \
 -f grafana/values.yaml \
 -f prometheus/values.yaml \
 -f grafana/secrets.yaml \
 --install --create-namespace \
 prometheus-community/kube-prometheus-stack
```

По окончанию открыть дашборды графаны по ссылке
http://grafana.158.160.132.73.sslip.io/d/k8s_views_global/kubernetes-views-global
http://grafana.158.160.132.73.sslip.io/d/d249cc23-6930-403e-91f6-c9c30389b88d/kubernetes-deployment-cpu-and-memory-metrics?orgId=1

Настроено правило: если количество подов превышает 55, то отправить уведомление в канал Telegram
http://grafana.158.160.132.73.sslip.io/alerting/grafana/ddc4a4d8-d2f4-413e-9dad-61ce9013a13a/view?returnTo=%2Falerting%2Flist

## 5. Logging

Для настройки логирования перейти в папку logging, исправить адреса хостов и запустить команды:
```shell
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx --namespace=nginx-ingress --create-namespace -f nginx-ingress.values.yaml
helm upgrade --install elasticsearch ./helm-charts-8.5.1/elasticsearch -n logging --create-namespace -f elasticsearch.values.yaml
helm upgrade --install kibana ./helm-charts-8.5.1/kibana -n logging --create-namespace -f kibana.values.yaml
helm upgrade --install fluent-bit fluent/fluent-bit -n logging -f fluent-bit.values.yaml --version 0.39.0
```

По окончанию открыть kibana по ссылке http://kibana.158.160.132.73.sslip.io/, создать Data View и создать на основе него дашбоард
