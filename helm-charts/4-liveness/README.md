# 4-liveness Helm Chart

## Purpose

This chart is **intentionally broken** for training. The container is running, but it gets restarted because the liveness/readiness probes are checking the wrong endpoint.

## The Problem

- The Deployment exposes the container on port **80**
- `values.yaml` configures probes to check port **8080** and paths that don’t exist for the default NGINX container
- Result: failed probes → restarts / not-ready Pods

## How to Reproduce

```bash
helm install liveness . -n exercise-01 --create-namespace
kubectl get pods -n exercise-01 -w
kubectl describe pod -n exercise-01 -l app.kubernetes.io/name=liveness-app
```

## Fix

Point probes at the correct port/path. Simplest working fix for NGINX is `/` on port `80`.

Example `fixed-values.yaml`:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80

readinessProbe:
  httpGet:
    path: /
    port: 80
```

Apply the fix:

```bash
helm upgrade liveness . -n exercise-01 -f fixed-values.yaml
```
