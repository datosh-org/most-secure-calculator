
## Deploy KinD

```sh
# Cache image locally, else cluster create will pull every time.
IMG=kindest/node:v1.27.3@sha256:3966ac761ae0136263ffdb6cfd4db23ef8a83cba8a463690e98317add2c9ba72
docker pull ${IMG}

kind create cluster \
    --image=${IMG} \
    --config=kind-config.yml
# Configure ko to use KinD
# https://ko.build/configuration/
export KO_DOCKER_REPO=kind.local

# Deploy ingress - NGINX
curl -L https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml > nginx.yml
kubectl apply -f nginx.yml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

## Terminate KinD

```sh
# Destroy cluster
kind delete cluster
```
