# 3-pending Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Pod stays in `Pending` because the resource requests are too high to be scheduled on your cluster.

## The Problem

- `values.yaml` requests very large CPU/memory (e.g. `requests.cpu: "8"`)
- The scheduler can’t find any node that satisfies the request
- You’ll see events like `0/… nodes are available: Insufficient cpu`

## How to Reproduce

`exercise-namespace` below is a Kubernetes namespace name (not a local repo folder). It is created automatically by `--create-namespace`.

Commands below must be run from a machine where this chart directory exists.

```bash
helm install pending . -n exercise-namespace --create-namespace
kubectl get pods -n exercise-namespace -w
kubectl describe pod -n exercise-namespace -l app.kubernetes.io/name=pending-app
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

The repository includes a ready-to-use `fixed-values.yaml` in this directory. This is a reference file to review structure. But it can be applied as is.

### Option 1 (Recommended): GitOps fix (persistent with ArgoCD)

In this environment, ArgoCD tracks:

- **Target Revision**: `argocd-active`
- **Path**: `helm-charts-new/3-pending`

So the persistent fix is:

```bash
cd /home/juls/terraform_proxmox/terraform_proxmox
git checkout argocd-active

# edit: helm-charts-new/3-pending/values.yaml
git add helm-charts-new/3-pending/values.yaml
git commit -m "fix(pending): lower resource requests/limits"
git push origin argocd-active
```

Then in ArgoCD, sync app `pending-helm` (or wait for auto-sync).

### Option 2: Run from laptop over SSH (no local Helm required, temporary override)

```bash
tar -cf - . \
| ssh root@192.168.122.100 '
  set -e
  kubectl get ns exercise-namespace >/dev/null 2>&1 || kubectl create ns exercise-namespace
  tmp=$(mktemp -d)
  tar -xf - -C "$tmp"
  helm template pending "$tmp" -f "$tmp/fixed-values.yaml" \
    | kubectl apply -n exercise-namespace -f -
  rm -rf "$tmp"
'
```
