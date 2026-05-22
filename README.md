# DevOps Engineer Technical Code Challenge

This repository contains my implementation for the DevOps Coding Challenge focused on deploying and automating the Azure AKS Store Demo application using Kubernetes, Terraform, Docker, and CI/CD practices.

---

# Approach and Implementation Strategy

To complete this challenge efficiently while minimizing infrastructure cost, I used a fully local-first DevOps workflow that still follows production-oriented engineering practices.

The implementation focuses on:

- Containerization and Kubernetes deployment
- Infrastructure as Code (IaC)
- CI/CD automation
- Reproducible deployments
- Kubernetes operational best practices

## Stack Used

- Docker
- Kubernetes using `kind`
- Terraform
- GitHub Actions
- GitHub Container Registry (GHCR)

---

# Important Notes and Constraints

Due to the requirement of providing credit card details for Azure DevOps and Azure subscription activation, I opted to use fully free alternatives for this implementation.

## Alternatives Used

| Preferred Technology | Alternative Used |
|---|---|
| Azure DevOps Pipelines | GitHub Actions |
| Azure Container Registry (ACR) | GitHub Container Registry (GHCR) |
| Azure Kubernetes Service (AKS) | Local Kubernetes cluster using kind |

The overall CI/CD and Kubernetes workflow remains aligned with real-world DevOps practices and production deployment patterns.

Note that I did not implement the CD portion because of the limitations I had regarding deploying and testing an AKS cluster.

Additionally, while the Terraform configuration for AKS and Azure resources was completed, it was not fully deployed or integration-tested against Azure due to the lack of an active Azure subscription under the same limitation mentioned above.

Terraform validation steps such as the following were still performed locally:

```bash
terraform init
terraform validate
terraform plan
```

---

# Repository Structure

```text
aks-store-devops/
├── app/
├── kubernetes/
├── terraform/
├── .github/workflows/
├── docker-compose.yaml
└── README.md
```

---

# Step-by-Step Implementation Process

## Phase 1 — Repository Setup

The project repository was structured to separate infrastructure, application code, Kubernetes manifests, and CI/CD workflows for maintainability and scalability.

---

## Phase 2 — Application Preparation

The application source was based on the Azure AKS Store Demo repository.

I cloned the repository locally and, following the requirement not to include files directly from the AKS Demo repository, I only referenced the source application while building the Docker images from my own repository structure.

### Services Referenced

```text
app/store-front
app/store-admin
app/order-service
app/product-service
app/makeline-service
```

---

## Phase 3 — Containerization

Dockerfiles were created for both frontend and backend services.

### Objectives

- Standardize application runtime environments
- Enable portability across environments
- Prepare workloads for Kubernetes deployment

### Local Tests Performed

```bash
docker build \
  -f app/order-service/Dockerfile \
  -t order-service:local \
  ../aks-store-demo/src/order-service

docker run -p 8080:80 store-front:local
```

Each service image was tested locally before Kubernetes deployment.

Additionally, I tested the application locally using Docker Compose before deploying it to my local Kubernetes cluster. This helped me better understand how the applications communicate with supporting services such as MongoDB and RabbitMQ.

---

## Phase 4 — Local Kubernetes Deployment

To avoid cloud infrastructure costs while still validating Kubernetes functionality, a local Kubernetes cluster was created using `kind`.

### Local Cluster Setup

```bash
kind create cluster
```

---

# Ingress Configuration

Ingress support was added using the NGINX Ingress Controller to expose the frontend and admin applications through hostname-based routing.

### Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Verify the ingress controller:

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

---

## kind Cluster Configuration for Ingress

Since `kind` does not expose ports `80` and `443` by default, the cluster was recreated with extra port mappings to allow local access through ingress hostnames.

### kind-config.yaml

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
```

### Create the Cluster

```bash
kind create cluster --config kind-config.yaml
```

---

## Kubernetes Resources Created

### Resources Included

- Deployments
- Services
- Ingress resources
- ConfigMaps
- Secrets
- Namespace definitions

---

## Ingress Resources

Ingress resources were configured to expose the applications using hostname-based routing.

### Hosts Configured

- `store.local`
- `admin.store.local`

### Example Ingress Validation

```bash
kubectl describe ingress aks-store-ingress -n aks-store
```

Example output:

```text
Host               Path  Backends
----               ----  --------
store.local
                   /   store-front:80

admin.store.local
                   /   store-admin:80
```

---

## Deployment Validation

Deploy the Kubernetes manifests:

```bash
kubectl apply -f kubernetes/ --recursive
```

Verify resources:

```bash
kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A
```

---

## Local DNS Configuration

The following entries were added to `/etc/hosts` to allow local hostname resolution:

```text
127.0.0.1 store.local
127.0.0.1 admin.store.local
```

---

## Accessing the Applications

Frontend application:

```text
http://store.local
```

Admin application:

```text
http://admin.store.local
```

Example validation using curl:

```bash
curl -H "Host: store.local" http://localhost
curl -H "Host: admin.store.local" http://localhost
```

---

## Phase 5 — Infrastructure as Code (Terraform)

Terraform configuration files were created to provision Azure infrastructure resources.

### Terraform Files Created

```text
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
└── provider.tf
```

### Planned Infrastructure

- Azure Resource Group
- Azure Kubernetes Service (AKS)
- Azure Container Registry (ACR)

### Validation Performed

```bash
terraform init
terraform validate
terraform plan
```

### Limitation

The Terraform deployment was not fully executed against Azure because an active Azure subscription was unavailable due to the previously mentioned account and billing limitations.

However, the Terraform configuration was written following standard IaC practices and validated locally.

---

## Phase 6 — Continuous Integration (CI)

CI automation was implemented using GitHub Actions.

### CI Workflow Responsibilities

- Checkout repository source code
- Build Docker images
- Run validation/testing steps
- Push container images to GitHub Container Registry

### Workflow Location

```text
.github/workflows/ci.yml
```

### Container Registry Used

GitHub Container Registry (GHCR) was used as a free alternative to Azure Container Registry.

Example image push:

```bash
docker push ghcr.io/username/store-front:latest
```

---

## Phase 7 — Security and Operational Improvements

Additional Kubernetes operational best practices were included.

### Implemented Improvements

- Resource requests and limits
- Namespace isolation
- ConfigMap and Secret separation
- Optional Network Policies

### Example Resource Limits

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```
