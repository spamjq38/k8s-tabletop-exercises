# Tabletop Exercises - GitOps Repository

Kubernetes troubleshooting exercises deployed via ArgoCD.

## Quick Start

**Edit any file → git push → ArgoCD deploys automatically**

## Repository Structure

```
├── manifests/              # ArgoCD deploys everything here
│   ├── namespaces/        # Exercise namespaces
│   └── README.md
├── exercises/              # Training scenarios and documentation
│   ├── scenarios/
│   │   ├── 01-crashloop/
│   │   ├── 02-service-port/
│   │   ├── 03-imagepull/
│   │   ├── 04-config/
│   │   └── 05-scheduling/
│   ├── README.md
│   └── TROUBLESHOOTING_PLAYBOOK.md
└── helm-charts/            # Helm charts for exercises
    ├── memory-hog/
    └── broken-service/
```

## How to Deploy an Exercise

1. Copy scenario manifest to `manifests/`:
   ```bash
   cp exercises/scenarios/01-crashloop/broken-deployment.yaml manifests/exercise-01-app.yaml
   ```

2. Commit and push:
   ```bash
   git add manifests/exercise-01-app.yaml
   git commit -m "Deploy exercise 01"
   git push
   ```

3. ArgoCD auto-deploys within 3 minutes

## How to Update Documentation

1. Edit any file in `exercises/`:
   ```bash
   nano exercises/scenarios/02-service-port/README.md
   ```

2. Commit and push:
   ```bash
   git add .
   git commit -m "Update scenario 02 instructions"
   git push
   ```

## How to Modify Helm Charts

1. Edit chart files:
   ```bash
   nano helm-charts/memory-hog/values.yaml
   ```

2. Commit and push:
   ```bash
   git add .
   git commit -m "Update memory-hog resources"
   git push
   ```

## ArgoCD Dashboard

- **URL:** https://192.168.122.100:30443
- **App:** `tabletop-exercises`
- **Namespace:** `argocd`

## Available Exercises

1. **01-crashloop** - OOMKilled debugging
2. **02-service-port** - Service networking issues
3. **03-imagepull** - ImagePullBackOff troubleshooting
4. **04-config** - ConfigMap and Secret problems
5. **05-scheduling** - Node selectors and taints

## Setup

See infrastructure repo for Terraform setup that creates the ArgoCD application pointing to this repo.
