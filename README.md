# aks-store-devops

DevOps project for the [Azure AKS Store Demo](https://github.com/Azure-Samples/aks-store-demo): custom Dockerfiles, local orchestration with Docker Compose, and Kubernetes manifests for deployment.

Application **source code** lives in a separate clone of `aks-store-demo`. This repo holds infrastructure, Docker build definitions, and Kubernetes YAML.

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Build images and run Compose locally |
| [Git](https://git-scm.com/) | Clone repositories |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Deploy to Kubernetes (optional locally) |
| Local Kubernetes (optional) | [kind](https://kind.sigs.k8s.io/), [minikube](https://minikube.sigs.k8s.io/), or AKS |

## Repository layout

```
aks-store-devops/
├── app/                    # Dockerfiles (one per service)
├── docker-compose.yml      # Full stack for local development
├── rabbitmq_enabled_plugins
├── kubernetes/             # Manifests (Deployments, Services, Ingress, etc.)
│   ├── namespace.yaml
│   ├── configmaps/
│   ├── secrets/
│   ├── ingress/
│   ├── mongodb/
│   ├── rabbitmq/
│   ├── store-front/
│   ├── store-admin/
│   ├── order-service/
│   ├── product-service/
│   ├── makeline-service/
│   └── ai-service/
└── README.md
```

## Getting started

### 1. Clone this repo and the demo app

Both repositories should be **sibling folders** under the same parent directory (e.g. `code/`):

```bash
cd ~/code   # or your preferred parent folder

git clone https://github.com/<your-org>/aks-store-devops.git
git clone https://github.com/Azure-Samples/aks-store-demo.git
```

Expected layout:

```
code/
├── aks-store-devops/     # this repo
└── aks-store-demo/       # application source
    └── src/
        ├── store-front/
        ├── store-admin/
        ├── order-service/
        └── ...
```

### 2. RabbitMQ plugins file

Ensure `rabbitmq_enabled_plugins` exists at the repo root (a **file**, not a directory). It is required by `docker-compose.yml`:

```
[rabbitmq_management,rabbitmq_prometheus,rabbitmq_amqp1_0].
```

If Docker previously created an empty directory with that name, remove it and recreate the file:

```bash
rm -rf rabbitmq_enabled_plugins
printf '%s\n' '[rabbitmq_management,rabbitmq_prometheus,rabbitmq_amqp1_0].' > rabbitmq_enabled_plugins
```

---

## Run locally with Docker Compose (recommended)

This starts MongoDB, RabbitMQ, all app services, and optional virtual customer/worker simulators.

```bash
cd aks-store-devops
docker compose up -d --build
```

Watch status:

```bash
docker compose ps
```

### Access URLs (Compose)

| Service | URL | Notes |
|---------|-----|--------|
| **Store front** | http://localhost:8080 | Customer UI |
| **Store admin** | http://localhost:8081 | Admin UI |
| **Order service** | http://localhost:3000/health | API |
| **Product service** | http://localhost:3002/health | API |
| **Makeline service** | http://localhost:3001/health | API |
| **RabbitMQ management** | http://localhost:15672 | User: `username`, Password: `password` |

### Stop the stack

```bash
docker compose down
```

Remove volumes as well (clean database/queue state):

```bash
docker compose down -v
```

### How Compose builds images

- **Dockerfile** → `app/<service>/Dockerfile` (this repo)
- **Build context** → `../aks-store-demo/src/<service>` (demo source)

Override the demo path if needed:

```bash
export AKS_STORE_DEMO=/path/to/aks-store-demo
docker compose up -d --build
```

---

## Build images manually

From `aks-store-devops`, build a single service:

```bash
SERVICE=store-front
docker build \
  -f app/${SERVICE}/Dockerfile \
  -t ${SERVICE}:local \
  ../aks-store-demo/src/${SERVICE}
```

All services:

```bash
for svc in store-front store-admin order-service product-service makeline-service ai-service; do
  docker build -f app/${svc}/Dockerfile -t ${svc}:local ../aks-store-demo/src/${svc}
done
```

Run one container (example):

```bash
docker run -d -p 8080:8080 store-front:local
```

---

## Run on Kubernetes (local cluster)

Manifests target the `aks-store` namespace and assume cluster DNS names match service names (`order-service`, `rabbitmq`, etc.). Configuration is aligned with `docker-compose.yml` (ports, RabbitMQ credentials, MongoDB URI, etc.).

### 1. Build and make images available

Build images as above, then either:

**kind** — load images into the cluster:

```bash
for svc in store-front store-admin order-service product-service makeline-service ai-service; do
  kind load docker-image ${svc}:local
done
```

Update each `kubernetes/*/deployment.yaml` image to `<service>:local` if you use the `:local` tag.

**minikube** — use Minikube’s Docker daemon:

```bash
eval $(minikube docker-env)
# rebuild images here so they exist inside minikube
```

**AKS** — push to Azure Container Registry and set image names in deployments (e.g. `myacr.azurecr.io/store-front:v1`).

### 2. Install an Ingress controller (for HTTP routing)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

### 3. Deploy manifests

```bash
cd aks-store-devops
kubectl apply -f kubernetes/ --recursive
```

Or apply in order:

```bash
cd kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f configmaps/
kubectl apply -f secrets/
kubectl apply -f mongodb/ -f rabbitmq/
kubectl apply -f order-service/ -f makeline-service/ -f product-service/ -f ai-service/
kubectl apply -f store-front/ -f store-admin/
kubectl apply -f ingress/
```

### 4. Verify

```bash
kubectl get pods -n aks-store
kubectl get ingress -n aks-store
```

### Access URLs (Kubernetes)

Ingress hosts (see `kubernetes/ingress/ingress.yaml`):

```bash
INGRESS_IP=$(kubectl get ingress aks-store-ingress -n aks-store -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "$INGRESS_IP  store.local admin.store.local" | sudo tee -a /etc/hosts
```

| App | URL |
|-----|-----|
| Store front | http://store.local |
| Store admin | http://admin.store.local |

**Without Ingress** — port-forward:

```bash
kubectl port-forward -n aks-store svc/store-front 8080:80
kubectl port-forward -n aks-store svc/store-admin 8081:80
```

Then open http://localhost:8080 and http://localhost:8081.

### ai-service secrets

Before using AI features, set keys in `kubernetes/secrets/app-secrets.yaml` (`OPENAI_API_KEY`, Azure OpenAI fields, etc.), then re-apply:

```bash
kubectl apply -f kubernetes/secrets/
kubectl rollout restart deployment/ai-service -n aks-store
```

### Tear down Kubernetes resources

```bash
kubectl delete -f kubernetes/ --recursive
# or
kubectl delete namespace aks-store
```

---

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| `path ... not found` on `docker build` | Demo repo is a sibling at `../aks-store-demo` |
| RabbitMQ mount error | `rabbitmq_enabled_plugins` must be a **file**, not a directory |
| `order-service` not running | RabbitMQ healthy? `docker compose logs rabbitmq` |
| store-front / store-admin **unhealthy** | Rebuild after Dockerfile/nginx changes: `docker compose up -d --build store-front store-admin` |
| Kubernetes `ImagePullBackOff` | Image not in cluster — load into kind/minikube or push to ACR |
| Ingress not reachable | Controller installed? `kubectl get ingress -n aks-store` |

---

## License

See [LICENSE](LICENSE).
