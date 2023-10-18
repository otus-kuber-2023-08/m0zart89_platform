images:
  repository: gcr.io/google-samples/microservices-demo
  # Overrides the image tag whose default is the chart appVersion.
  tag: "v0.8.0"
redis:
  #architecture: standalone
  sentinel:
    enabled: true
  fullnameOverride: redis-cart
  auth:
    enabled: false
    sentinel: false
fronend:
  external_ip: $EXTERNAL_IP