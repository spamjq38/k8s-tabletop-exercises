# Memory Hog Helm Chart

## Purpose

This chart is **intentionally broken** for training purposes. It deploys a pod that allocates a lot of memory while having an artificially low memory limit, causing it to be OOMKilled.

## The Problem

- **Application allocates:** ~200Mi of memory
- **Limit configured:** 50Mi
- **Result:** Container is killed (often `OOMKilled`, exit code 137)

## Usage

```bash
# Install the broken chart
helm install memory-app . -n exercise-01

# Watch it fail
kubectl get pods -n exercise-01 -w

# Diagnose the issue
kubectl describe pod <pod-name> -n exercise-01
kubectl logs <pod-name> -n exercise-01 --previous
```

## Fixing It

Create a `fixed-values.yaml`:

```yaml
resources:
  limits:
    memory: 256Mi
    cpu: 200m
  requests:
    memory: 128Mi
    cpu: 100m
```

Apply the fix:

```bash
helm upgrade memory-app . -n exercise-01 -f fixed-values.yaml
```

## Learning Objectives

After fixing this chart, you will understand:

- How to diagnose OOMKilled containers
- The difference between resource requests and limits
- How to use `kubectl describe` and `kubectl logs`
- How to fix issues via Helm upgrades
