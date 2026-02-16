# 3-pending Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Pod stays in `Pending` because the resource requests are too high to be scheduled on your cluster.

## The Problem

- `values.yaml` requests very large CPU/memory (e.g. `requests.cpu: "8"`)
- The scheduler can’t find any node that satisfies the request
- You’ll see events like `0/… nodes are available: Insufficient cpu`

## How to Reproduce

```bash
helm install pending . -n exercise-01 --create-namespace
kubectl get pods -n exercise-01 -w
kubectl describe pod -n exercise-01 -l app.kubernetes.io/name=pending-app
```

## Fix

Lower `resources.requests`/`resources.limits` to fit your nodes. Example `fixed-values.yaml`:

```yaml
resources:
  limits:
    cpu: "250m"
    memory: 256Mi
  requests:
    cpu: "100m"
    memory: 128Mi
```

Apply the fix:

```bash
helm upgrade pending . -n exercise-01 -f fixed-values.yaml
```
