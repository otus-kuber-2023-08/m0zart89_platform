# Preparation:
1. git clone ...
2. create locals.tf:
```terraform
locals {
  cloud_id    = "b1gcfjb..."
  folder_id   = "b1gtvjl..."
  k8s_version = "1.24"
  sa_name     = "myaccount"
  allowed_ips = ["my.ip.add.ress"]
}

```
3. create api-key with `yc iam key create --service-account-name <...> -o auth.json` 
```terraform
{
   "id": "ajefti...",
   "service_account_id": "aje2pu...",
   "created_at": "2023-...",
   "key_algorithm": "RSA_2048",
   "public_key": "-----BEGIN PUBLIC KEY-----\nMII...",
   "private_key": "-----BEGIN PRIVATE KEY-----\nMII..."
}
```
4. terraform plan
5. terraform apply