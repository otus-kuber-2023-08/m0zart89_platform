# Курсовая работа

## Тема

Инфраструктурная managed k8s платформа для онлайн магазина microservices-demo

## Содержание

1. Описание
2. IaC
3. Подготовка
4. CI/CD
5. Monitoring
6. Logging
7. Выводы

## 1. Описание

Платформа состоит из:
1. репозитория проекта https://github.com/otus-kuber-2023-08/m0zart89_platform/tree/kubernetes-project/kubernetes-project
2. репозитория клиентского приложения https://gitlab.com/m0zart89/microservices-demo
3. кластера в Yandex Cloud https://cloud.yandex.ru/ru/services/managed-kubernetes

Развёртывание производится с помощью `Terraform` https://www.terraform.io/

CI строится на `Gitlab` https://gitlab.com/ и `ArgoCD` https://argo-cd.readthedocs.io/en/stable/.

Мониторинг на основе `Prometheus` https://prometheus.io/ и `Grafana` https://grafana.com/.

Логирование на основе `EFK Stack`.

## 2. IaC

Для разворачивания кластера перейти в директорию **iac**, создать файл `auth.json` с содержимым:
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

По окончанию операции (займёт ~7 минут) разверётся кластер, контекст которого пропишется как основной


## 3. Подготовка

Перейти в директорию **cert-manager** и выполнить команду:
```shell
helm upgrade --install cert-manager jetstack/cert-manager --namespace=cert-manager --create-namespace --set installCRDs=true
kubectl apply -f ./cert-manager/issuer-letsencrypt-production.yaml
```

По окончанию операции (займёт ~7 минут) разверётся кластер, контекст которого пропишется как основной

## 4. CICD



Для настройки IaC перейти в папку **cicd** и выполнить команды:

```shell
kubectl create namespace argocd
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -n argocd
kubectl apply -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml -n argocd
kubectl apply -f argocd_ingress_rule.yaml -n argocd
kubectl apply -f frontend_ingress_rule.yaml -n argocd
kubectl apply -f app.yaml -n argocd
```

Для проверки IaC необходимо сделать коммит исходный код образов контейнеров или helm-чарты репозитория клиентского приложения https://gitlab.com/m0zart89/microservices-demo

По окончанию build текущий образ заменится последним (digest)

[.gitlab-ci.yaml](https://gitlab.com/m0zart89/microservices-demo/-/blob/main/.gitlab-ci.yml?ref_type=heads)

Сайт доступен по адресу: https://shop.158.160.132.73.sslip.io/

## 5. Monitoring

Для настройки мониторинга перейти в папку **monitoring**, исправить адреса хостов и выполнить команды:
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
![alt text for screen readers](https://raw.githubusercontent.com/otus-kuber-2023-08/m0zart89_platform/kubernetes-project/kubernetes-project/monitoring/cluster.png)
http://grafana.158.160.132.73.sslip.io/d/d249cc23-6930-403e-91f6-c9c30389b88d/kubernetes-deployment-cpu-and-memory-metrics?orgId=1
![alt text for screen readers](https://raw.githubusercontent.com/otus-kuber-2023-08/m0zart89_platform/kubernetes-project/kubernetes-project/monitoring/client.png)

Настроено правило: если количество подов превышает 55, то отправить уведомление в канал Telegram
http://grafana.158.160.132.73.sslip.io/alerting/grafana/ddc4a4d8-d2f4-413e-9dad-61ce9013a13a/view?returnTo=%2Falerting%2Flist
![alt text for screen readers](https://raw.githubusercontent.com/otus-kuber-2023-08/m0zart89_platform/kubernetes-project/kubernetes-project/monitoring/telegram.png)

## 6. Logging

Для настройки логирования перейти в папку **logging**, исправить адреса хостов и запустить команды:
```shell
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx --namespace=nginx-ingress --create-namespace -f nginx-ingress.values.yaml
helm upgrade --install elasticsearch ./helm-charts-8.5.1/elasticsearch -n logging --create-namespace -f elasticsearch.values.yaml
helm upgrade --install kibana ./helm-charts-8.5.1/kibana -n logging --create-namespace -f kibana.values.yaml
helm upgrade --install fluent-bit fluent/fluent-bit -n logging -f fluent-bit.values.yaml --version 0.39.0
```

По окончанию открыть kibana по ссылке http://kibana.158.160.132.73.sslip.io/, создать Data View и создать на основе него дашбоард
![alt text for screen readers](https://raw.githubusercontent.com/otus-kuber-2023-08/m0zart89_platform/kubernetes-project/kubernetes-project/logging/kibana.png)

## 7. Выводы

С помощью современных инструментов была построена инфраструктура для клиентского приложения, непрерывная доставка осуществляется за несколько минут, для отслеживания состояния инфраструктуры имеется мониторинг и логирование.
