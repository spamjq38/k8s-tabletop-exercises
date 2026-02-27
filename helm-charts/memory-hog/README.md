# Memory Hog Helm Chart

## Purpose

This chart is **intentionally broken** for training purposes. It deploys a pod that allocates a lot of memory while having an artificially low memory limit, causing it to be OOMKilled.

## The Problem

- **Application allocates:** ~200Mi of memory
- **Limit configured:** 50Mi
- **Result:** Container is killed (often `OOMKilled`, exit code 137)

## Usage

`exercise-namespace` below is a Kubernetes namespace name (not a local repo folder). It is created automatically by `--create-namespace`.

```bash
# Install the broken chart
helm install memory-app . -n exercise-namespace --create-namespace

# Watch it fail
kubectl get pods -n exercise-namespace -w

# Diagnose the issue
kubectl describe pod <pod-name> -n exercise-namespace
kubectl logs <pod-name> -n exercise-namespace --previous
```

## Fixing It

The repository includes a ready-to-use `fixed-values.yaml` in this directory. This is a reference file to review structure. But it can be applied as is.

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

### Option 1 (Recommended): GitOps fix (persistent with ArgoCD)

In this environment, ArgoCD tracks:

- **Target Revision**: `argocd-active`
- **Path**: `helm-charts-new/memory-hog`

So the persistent fix is:

```bash
cd /home/juls/terraform_proxmox/terraform_proxmox
git checkout argocd-active

# edit: helm-charts-new/memory-hog/values.yaml
git add helm-charts-new/memory-hog/values.yaml
git commit -m "fix(memory-hog): raise memory limit"
git push origin argocd-active
```

Then in ArgoCD, sync app `memory-hog-helm` (or wait for auto-sync).

### Option 2: Run from laptop over SSH (no local Helm required, temporary override)

```bash
tar -cf - . \
| ssh root@192.168.122.100 '
  set -e
  kubectl get ns exercise-namespace >/dev/null 2>&1 || kubectl create ns exercise-namespace
  tmp=$(mktemp -d)
  tar -xf - -C "$tmp"
  helm template memory-app "$tmp" -f "$tmp/fixed-values.yaml" \
    | kubectl apply -n exercise-namespace -f -
  rm -rf "$tmp"
'
```

## Learning Objectives

After fixing this chart, you will understand:

- How to diagnose OOMKilled containers
- The difference between resource requests and limits
- How to use `kubectl describe` and `kubectl logs`
- How to fix issues via Helm upgrades
