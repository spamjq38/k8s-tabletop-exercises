# 7-rbac Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Pod runs `kubectl get pods -A` but the ServiceAccount has no RBAC permissions, so it fails with `Forbidden`.

## The Problem

- The chart creates a `ServiceAccount`
- It does **not** create any `Role`/`RoleBinding` (or `ClusterRoleBinding`)
- The container then tries to list pods across all namespaces

## How to Reproduce

`exercise-namespace` below is a Kubernetes namespace name (not a local repo folder). It is created automatically by `--create-namespace`.

Commands below must be run from a machine where this chart directory exists.

```bash
helm install rbac . -n exercise-namespace --create-namespace
kubectl logs -n exercise-namespace deploy/rbac-app
kubectl describe pod -n exercise-namespace -l app.kubernetes.io/name=rbac-app
```

## Fix

Grant permissions to the ServiceAccount used by the Deployment.

### Option A (cluster-wide, simplest for labs)

Bind the built-in `view` ClusterRole:

```bash
kubectl create clusterrolebinding rbac-app-view \
  --clusterrole=view \
  --serviceaccount=exercise-namespace:rbac-app
```

### Option 1 (Recommended): GitOps fix (persistent with ArgoCD)

In this environment, ArgoCD tracks:

- **Target Revision**: `argocd-active`
- **Path**: `helm-charts-new/7-rbac`

So the persistent fix is:

```bash
cd /home/juls/terraform_proxmox/terraform_proxmox
git checkout argocd-active

# edit: helm-charts-new/7-rbac/templates/deployment.yaml
git add helm-charts-new/7-rbac/templates/deployment.yaml
git commit -m "fix(rbac): grant required permissions"
git push origin argocd-active
```

Then in ArgoCD, sync app `rbac-helm` (or wait for auto-sync).

### Option 2: Run from laptop over SSH (temporary override)

```bash
ssh root@192.168.122.100 \
  'kubectl create clusterrolebinding rbac-app-view --clusterrole=view --serviceaccount=exercise-namespace:rbac-app'
```

### Option B (chart-level fix)

Add templates for a `Role`/`RoleBinding` (or `ClusterRoleBinding`) that grants the needed verbs/resources.
For example, allow listing pods:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: rbac-app-view
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: rbac-app
  namespace: exercise-namespace
```
