Устанавливаем consul и vault:
```shell
git clone https://github.com/hashicorp/consul-k8s.git
helm upgrade --install consul ./consul-k8s/charts/consul --values=consul.values.yaml
git clone https://github.com/hashicorp/vault-helm.git
helm upgrade --install vault vault-helm -f vault.values.yaml --atomic
```

Статус vault
```shell
helm status vault
NAME: vault
LAST DEPLOYED: Mon Mar  4 01:06:31 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://developer.hashicorp.com/vault/docs


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault
```

Инициализация и распаковка 
```shell
kubectl exec -it vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
kubectl exec -it vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -it vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -it vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY
```
Вывод первого хоста
```shell
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.15.2
Build Date      2023-11-06T11:33:28Z
Storage Type    consul
Cluster Name    vault-cluster-ae826abc
Cluster ID      d86e2ee1-7c4e-7a5b-807b-fcc181d98302
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
Active Since    2024-03-03T23:08:47.906522918Z
```

Вывод остальных хостов
```shell
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.15.2
Build Date             2023-11-06T11:33:28Z
Storage Type           consul
Cluster Name           vault-cluster-ae826abc
Cluster ID             d86e2ee1-7c4e-7a5b-807b-fcc181d98302
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.112.131.8:8200
```

kubectl exec -it vault-0 -- vault login
```shell
Token (will be hidden): 
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.ZqhCQeG2CXPeA7LdN6zsp145
token_accessor       o3QKoq1AdqRAnfQplREzhRQs
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

kubectl exec -it vault-0 -- vault auth list
```shell
Path      Type     Accessor               Description                Version
----      ----     --------               -----------                -------
token/    token    auth_token_25ff8d74    token based credentials    n/a
```

Секреты
```shell
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
Success! Enabled the kv secrets engine at: otus/

kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
Success! Enabled the kv secrets engine at: otus/

kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
Success! Enabled the kv secrets engine at: otus/

kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-rw/config

kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-rw/config

kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-rw/config
```

Авторизация Kubernetes
```shell
kubectl exec -it vault-0 -- vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/

kubectl exec -it vault-0 -- vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/

kubectl apply --filename vault-auth-service-account.yaml
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
serviceaccount/vault-auth created
secret/vault-auth-secret created
```

Настройка конфига авторизации Kubernetes
```shell
export SA_SECRET_NAME=$(kubectl get secrets --output=json    | jq -r '.items[].metadata | select(.name|startswith("vault-auth-")).name')
export SA_JWT_TOKEN=$(kubectl get secret $SA_SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl config view --raw --minify --flatten   --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
export K8S_HOST=$(kubectl config view --raw --minify --flatten   --output 'jsonpath={.clusters[].cluster.server}')

kubectl exec -it vault-0 -- vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="$K8S_HOST" kubernetes_ca_cert="$SA_CA_CRT" issuer="https://kubernetes.default.svc.cluster.local"
Success! Data written to: auth/kubernetes/config
```

Настройка роли
```shell
kubectl cp --no-preserve=false otus-policy.hcl vault-0:/tmp
kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
Success! Uploaded policy: otus-policy
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus bound_service_account_names=vault-auth bound_service_account_namespaces=default token_policies=otus-policy ttl=24h
Success! Data written to: auth/kubernetes/role/otus
```

Настройка тестового пода и работа с секретами
```shell
kubectl exec -it vault-test -- sh
apt update && apt install jq -y
kubectl exec -it vault-test -- sh
curl http://vault:8200/v1/sys/seal-status
export VAULT_ADDR=http://vault:8200
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl -s  --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-ro/config | jq
{
  "request_id": "2c0242ce-c8b0-e938-d9ad-d868a20195e2",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}

#создание
curl -s --request POST --data '{"bar": "baz"}' --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq

#редактирование
curl -s --request POST --data '{"bar": "baz"}' --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}

# Добавим разрешение на редактирование существующего ключа
# cat otus-policy.hcl
# path "otus/otus-ro/*" {
#     capabilities = ["read", "list"]
# }
# path "otus/otus-rw/*" {
#     capabilities = ["read", "create", "update", "list"]
# }

#редактирование
curl -s --request POST --data '{"bar": "baz"}' --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq

#чтение
curl -s --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq
{
  "request_id": "03976be3-8d84-ba5f-fc11-703182bfb85b",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

Доставим ключ в под nginx
```shell
kubectl create configmap example-vault-agent-config --from-file=./configs-k8s/
configmap/example-vault-agent-config created
kubectl get configmap example-vault-agent-config -o yaml
kubectl apply -f example-k8s-spec.yaml
pod/vault-agent-example created

kubectl exec -it vault-agent-example -- sh
cat /usr/share/nginx/html/index.html
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>
```

Запустим PKI
```shell
kubectl exec -it vault-0 -- vault secrets enable pki 
Success! Enabled the pki secrets engine at: pki/
kubectl exec -it vault-0 -- vault secrets enable pki 
Success! Enabled the pki secrets engine at: pki/
kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="example.com" ttl=87600h > CA_cert.crt
```

Пропишем урлы для CA и отозванных сертификатов
```shell
kubectl exec -it vault-0 -- vault write pki/config/urls \
issuing_certificates="http://vault:8200/v1/pki/ca" \
crl_distribution_points="http://vault:8200/v1/pki/crl"
Key                        Value
---                        -----
crl_distribution_points    [http://vault:8200/v1/pki/crl]
enable_templating          false
issuing_certificates       [http://vault:8200/v1/pki/ca]
ocsp_servers               []
```

Создадим промежуточный сертификат
```shell
kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal \
common_name="example.com Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
```

Пропишем промежуточный сертификат в vault
```shell
kubectl cp pki_intermediate.csr vault-0:/tmp
kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate \
csr=@/tmp/pki_intermediate.csr \
format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem

kubectl cp intermediate.cert.pem vault-0:/tmp
kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
```

Создадим роль для выдачи сертификатов
```shell
kubectl exec -it vault-0 -- vault write pki_int/roles/vault-example-com    allowed_domains="example.com" allow_subdomains=true max_ttl="720h"
```

Выпустим сертификат
```shell
kubectl exec -it vault-0 -- vault write pki_int/issue/vault-example-com common_name="*.example.com" ttl="24h"
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDnjCCAoagAwIBAgIUaolsPisnJhIgkR92NyQWLcy1OJUwDQYJKoZIhvcNAQEL
...
Vvu1FqDAKHJ/ovPJkNnb4FeiGgiA0+1ZKAWaD53MnC9lnu6SiNLdNKsftZkYJvJA
MWE0pjxtkZa+2tIgKXe9JdMp
-----END CERTIFICATE----- -----BEGIN CERTIFICATE-----
MIIDNTCCAh2gAwIBAgIUfayfUMCa2EzC0OIjelZXwf2sQGkwDQYJKoZIhvcNAQEL
...
cuqbxf0BuqtCtjyuKcn7N6B5DnN+FrYDT2i7IPhMO9AZfh4w9pI6NPkgD9+4U7NM
J2F4n4rVLFpx
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDYDCCAkigAwIBAgIUTRqO2mA8U8KoAAwOCQ81iAs73zUwDQYJKoZIhvcNAQEL
...
EvSQeC60i6urFlJipQyLrHa0WpRCTs9TOTmeB8vmkK/2XCx3R/UzbkjiNtFGSXuQ
DtVoYA==
-----END CERTIFICATE-----
expiration          1709595848
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnjCCAoagAwIBAgIUaolsPisnJhIgkR92NyQWLcy1OJUwDQYJKoZIhvcNAQEL
...
Vvu1FqDAKHJ/ovPJkNnb4FeiGgiA0+1ZKAWaD53MnC9lnu6SiNLdNKsftZkYJvJA
MWE0pjxtkZa+2tIgKXe9JdMp
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAuFbBVXr//V+5/p5jdErCUAhocz0F2jc0NeMMcic2KQk+y+iC
...
d13n46TqbTZf5tXhTiUG9Wvgw0yW5m9Ag1DCaMN1K/uvcUj42mkkWJtbglio+w6+
hFslx1v+CCNVIPccHT4ueJqSDB/SqXVMpBdAN8TtyxAGh/4d3rsg
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       4d:1a:8e:da:60:3c:53:c2:a8:00:0c:0e:09:0f:35:88:0b:3b:df:35
```

Отзовём сертификат
```shell
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="4d:1a:8e:da:60:3c:53:c2:a8:00:0c:0e:09:0f:35:88:0b:3b:df:35"
Key                        Value
---                        -----
revocation_time            1709509546
revocation_time_rfc3339    2024-03-03T23:45:46.479353727Z
state                      revoked
```