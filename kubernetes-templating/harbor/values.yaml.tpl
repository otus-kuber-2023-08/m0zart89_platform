expose:
  type: ingress
  ingress:
    hosts:
      core: harbor.$EXTERNAL_IP.sslip.io
    annotations:
      kubernetes.io/ingress.class: "nginx"
      cert-manager.io/cluster-issuer: "letsencrypt-production"
externalURL: https://harbor.$EXTERNAL_IP.sslip.io
