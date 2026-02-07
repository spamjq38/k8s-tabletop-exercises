# Helm Chart Exercises

This directory contains namespaces for Helm-based exercises.

## Available Helm Exercises

1. **memory-hog** - OOMKilled debugging with Helm-managed deployment
2. **broken-service** - Service networking issues with Helm chart

## How to Deploy Helm Charts

### Via ArgoCD (Recommended)

ArgoCD automatically creates the namespaces. To deploy the actual Helm charts, SSH to the control plane:

```bash
# SSH to control plane
ssh root@192.168.122.100

# Deploy memory-hog chart
helm install memory-app /root/tabletop-exercises/helm-charts/memory-hog -n exercise-memory-hog

# Deploy broken-service chart  
helm install broken-app /root/tabletop-exercises/helm-charts/broken-service -n exercise-broken-service
```

### Via GitOps (Advanced)

To make Helm charts fully GitOps-managed, create ArgoCD Application resources for each chart:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: memory-hog-helm
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/spamjq38/k8s-tabletop-exercises.git
    targetRevision: main
    path: helm-charts/memory-hog
    helm:
      releaseName: memory-app
  destination:
    server: https://kubernetes.default.svc
    namespace: exercise-memory-hog
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Add this to `manifests/helm-apps/` to have ArgoCD manage Helm deployments automatically.

## Exercise Scenarios

### Memory-Hog Exercise
- **Namespace:** exercise-memory-hog
- **Chart:** helm-charts/memory-hog
- **Problem:** Application crashes with OOMKilled
- **Goal:** Identify and fix resource limit issues

### Broken-Service Exercise
- **Namespace:** exercise-broken-service
- **Chart:** helm-charts/broken-service
- **Problem:** Service cannot connect to pods
- **Goal:** Fix service port mismatch
