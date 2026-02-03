# Memory Hog Helm Chart

## Purpose

This chart is **intentionally broken** for training purposes. It deploys a memory stress-test pod with insufficient memory limits, causing it to be OOMKilled.

## The Problem

- **Application needs:** 128Mi of memory
- **Limit configured:** 50Mi
- **Result:** Pod crashes with OOMKilled status

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
    memory: "256Mi"
    cpu: "200m"
  requests:
    memory: "128Mi"
    cpu: "100m"
```

Apply the fix:

```bash
helm upgrade memory-app . -n exercise-01 -f fixed-values.yaml
```

## Values

| Parameter | Default | Description |
|-----------|---------|-------------|
| `replicaCount` | `1` | Number of pods |
| `image.repository` | `polinux/stress` | Container image |
| `image.tag` | `latest` | Image tag |
| `resources.limits.memory` | `50Mi` | ❌ Too low (intentional) |
| `resources.requests.memory` | `50Mi` | ❌ Too low (intentional) |
| `stressArgs` | 128M allocation | Memory stress test parameters |

## Learning Objectives

After fixing this chart, you will understand:

- How to diagnose OOMKilled containers
- The difference between resource requests and limits
- How to use `kubectl describe` and `kubectl logs`
- How to fix issues via Helm upgrades
