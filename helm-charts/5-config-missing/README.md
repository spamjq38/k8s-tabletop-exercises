# 5-config-missing Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Pod fails because it references a ConfigMap and Secret that don’t exist.

## The Problem

- The Deployment sets env vars from:
  - `configMapName: missing-config` (key `config.txt`)
  - `secretName: missing-secret` (key `api-key`)
- Since those objects are not created by the chart, the Pod won’t start

## How to Reproduce

```bash
helm install config-missing . -n exercise-01 --create-namespace
kubectl get pods -n exercise-01 -w
kubectl describe pod -n exercise-01 -l app.kubernetes.io/name=config-app
```

## Fix (Option A: Create the missing objects)

```bash
kubectl -n exercise-01 create configmap missing-config --from-literal=config.txt="hello"

kubectl -n exercise-01 create secret generic missing-secret --from-literal=api-key="changeme"
```

Then restart/upgrade:

```bash
helm upgrade config-missing . -n exercise-01
```

## Fix (Option B: Change the references)

If you already have a ConfigMap/Secret in the namespace, point the chart at them.
Example `fixed-values.yaml`:

```yaml
configMapName: "my-config"
secretName: "my-secret"
```

```bash
helm upgrade config-missing . -n exercise-01 -f fixed-values.yaml
```
