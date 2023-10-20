ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-production"
    cert-manager.io/acme-challenge-type: http01
  hosts:
    - name: chartmuseum.$EXTERNAL_IP.sslip.io
      path: /
      tls: true
      tlsSecret: chartmuseum.$EXTERNAL_IP.sslip.io
