# broken-service Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Service routes traffic to the wrong `targetPort`, so requests fail even though the Pod is running.

## The Problem

- The container runs `python -m http.server 8080` (listening on **8080**)
- `values.yaml` sets `service.targetPort: 9090`
- Result: the Service sends traffic to a port where nothing is listening

## How to Reproduce

```bash
helm install broken-service . -n exercise-01 --create-namespace
kubectl get svc,pods -n exercise-01
kubectl describe svc -n exercise-01 broken-app

# Try reaching the service
kubectl -n exercise-01 port-forward svc/broken-app 8080:80
curl -v http://127.0.0.1:8080/
```

## Fix

Make `service.targetPort` match the container port (`8080`). Example `fixed-values.yaml`:

```yaml
service:
  targetPort: 8080
```

Apply the fix:

```bash
helm upgrade broken-service . -n exercise-01 -f fixed-values.yaml
```
