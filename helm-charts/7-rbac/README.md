# 7-rbac Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Pod runs `kubectl get pods -A` but the ServiceAccount has no RBAC permissions, so it fails with `Forbidden`.

## The Problem

- The chart creates a `ServiceAccount`
- It does **not** create any `Role`/`RoleBinding` (or `ClusterRoleBinding`)
- The container then tries to list pods across all namespaces

## How to Reproduce

```bash
helm install rbac . -n exercise-01 --create-namespace
kubectl logs -n exercise-01 deploy/rbac-app
kubectl describe pod -n exercise-01 -l app.kubernetes.io/name=rbac-app
```

## Fix

Grant permissions to the ServiceAccount used by the Deployment.

### Option A (cluster-wide, simplest for labs)

Bind the built-in `view` ClusterRole:

```bash
kubectl create clusterrolebinding rbac-app-view \
  --clusterrole=view \
  --serviceaccount=exercise-01:rbac-app
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
  namespace: exercise-01
```
