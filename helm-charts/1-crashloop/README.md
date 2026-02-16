# 1-crashloop Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Pod enters `CrashLoopBackOff` because the container command points to a binary that does not exist.

## The Problem

- In `values.yaml`, `containerCommand` is set to `/bin/invalid-command`
- The container exits immediately with a non-zero exit code
- Kubernetes restarts it, resulting in `CrashLoopBackOff`

## How to Reproduce

```bash
helm install crashloop . -n exercise-01 --create-namespace
kubectl get pods -n exercise-01 -w
kubectl describe pod -n exercise-01 -l app.kubernetes.io/name=crashloop-app
kubectl logs -n exercise-01 -l app.kubernetes.io/name=crashloop-app --previous
```

## Fix

Use a valid command (BusyBox includes `/bin/sh`). Example `fixed-values.yaml`:

```yaml
containerCommand:
  - /bin/sh
containerArgs:
  - -c
  - "echo ok; sleep 3600"
```

Apply the fix:

```bash
helm upgrade crashloop . -n exercise-01 -f fixed-values.yaml
```
