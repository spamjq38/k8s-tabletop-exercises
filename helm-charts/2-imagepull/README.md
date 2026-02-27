# 2-imagepull Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Pod enters `ImagePullBackOff` because the image tag does not exist.

## The Problem

- `values.yaml` uses `image.repository: nginx`
- But `image.tag` is set to a non-existent tag (`non-existent-tag-xyz123`)
- The node cannot pull the image, so the Pod never starts

## How to Reproduce

`exercise-namespace` below is a Kubernetes namespace name (not a local repo folder). It is created automatically by `--create-namespace`.

Commands below must be run from a machine where this chart directory exists.

```bash
helm install imagepull . -n exercise-namespace --create-namespace
kubectl get pods -n exercise-namespace -w
kubectl describe pod -n exercise-namespace -l app.kubernetes.io/name=imagepull-app
```

## Fix

Set `image.tag` to a real tag (for example `latest`). Example `fixed-values.yaml`:

```yaml
image:
  repository: nginx
  tag: "latest"
```

Apply the fix:

The repository includes a ready-to-use `fixed-values.yaml` in this directory. This is a reference file to review structure. But it can be applied as is.

### Option 1 (Recommended): GitOps fix (persistent with ArgoCD)

In this environment, ArgoCD tracks:

- **Target Revision**: `argocd-active`
- **Path**: `helm-charts-new/2-imagepull`

So the persistent fix is:

```bash
cd /home/juls/terraform_proxmox/terraform_proxmox
git checkout argocd-active

# edit: helm-charts-new/2-imagepull/values.yaml
git add helm-charts-new/2-imagepull/values.yaml
git commit -m "fix(imagepull): use valid image tag"
git push origin argocd-active
```

Then in ArgoCD, sync app `imagepull-helm` (or wait for auto-sync).

### Option 2: Run from laptop over SSH (no local Helm required, temporary override)

```bash
tar -cf - . \
| ssh root@192.168.122.100 '
  set -e
  kubectl get ns exercise-namespace >/dev/null 2>&1 || kubectl create ns exercise-namespace
  tmp=$(mktemp -d)
  tar -xf - -C "$tmp"
  helm template imagepull "$tmp" -f "$tmp/fixed-values.yaml" \
    | kubectl apply -n exercise-namespace -f -
  rm -rf "$tmp"
'
```
