# 4-liveness Helm Chart

## Purpose

This chart is **intentionally broken** for training. The container is running, but it gets restarted because the liveness/readiness probes are checking the wrong endpoint.

## The Problem

- The Deployment exposes the container on port **80**
- `values.yaml` configures probes to check port **8080** and paths that don’t exist for the default NGINX container
- Result: failed probes → restarts / not-ready Pods

## How to Reproduce

`exercise-namespace` below is a Kubernetes namespace name (not a local repo folder). It is created automatically by `--create-namespace`.

Commands below must be run from a machine where this chart directory exists.

```bash
helm install liveness . -n exercise-namespace --create-namespace
kubectl get pods -n exercise-namespace -w
kubectl describe pod -n exercise-namespace -l app.kubernetes.io/name=liveness-app
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

The repository includes a ready-to-use `fixed-values.yaml` in this directory. This is a reference file to review structure. But it can be applied as is.

### Option 1 (Recommended): GitOps fix (persistent with ArgoCD)

In this environment, ArgoCD tracks:

- **Target Revision**: `argocd-active`
- **Path**: `helm-charts-new/4-liveness`

So the persistent fix is:

```bash
cd /home/juls/terraform_proxmox/terraform_proxmox
git checkout argocd-active

# edit: helm-charts-new/4-liveness/values.yaml
git add helm-charts-new/4-liveness/values.yaml
git commit -m "fix(liveness): correct probes"
git push origin argocd-active
```

Then in ArgoCD, sync app `liveness-helm` (or wait for auto-sync).

### Option 2: Run from laptop over SSH (no local Helm required, temporary override)

```bash
tar -cf - . \
| ssh root@192.168.122.100 '
  set -e
  kubectl get ns exercise-namespace >/dev/null 2>&1 || kubectl create ns exercise-namespace
  tmp=$(mktemp -d)
  tar -xf - -C "$tmp"
  helm template liveness "$tmp" -f "$tmp/fixed-values.yaml" \
    | kubectl apply -n exercise-namespace -f -
  rm -rf "$tmp"
'
```
