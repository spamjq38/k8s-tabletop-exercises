# Kubernetes Manifests

This directory contains all Kubernetes resources that ArgoCD deploys.

## Structure

- `namespaces/` - All namespace definitions
- `helm-releases/` - Helm chart releases (optional, for future use)

## How to Deploy Exercise

To deploy an exercise scenario, add its manifest here and commit:

```bash
# Example: Deploy scenario 01 broken app
kubectl apply -f ../exercises/scenarios/01-crashloop/broken-deployment.yaml -n exercise-01

# Or add the manifest here and let ArgoCD deploy it
cp ../exercises/scenarios/01-crashloop/broken-deployment.yaml manifests/exercise-01-app.yaml
git add manifests/exercise-01-app.yaml
git commit -m "Deploy exercise 01"
git push
```

ArgoCD will automatically sync within 3 minutes.
