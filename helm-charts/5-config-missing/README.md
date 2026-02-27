# 5-config-missing Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Pod fails because it references a ConfigMap and Secret that don’t exist.

## The Problem

- The Deployment sets env vars from:
  - `configMapName: missing-config` (key `config.txt`)
  - `secretName: missing-secret` (key `api-key`)
- Since those objects are not created by the chart, the Pod won’t start

## How to Reproduce

`exercise-namespace` below is a Kubernetes namespace name (not a local repo folder). It is created automatically by `--create-namespace`.

Commands below must be run from a machine where this chart directory exists.

```bash
helm install config-missing . -n exercise-namespace --create-namespace
kubectl get pods -n exercise-namespace -w
kubectl describe pod -n exercise-namespace -l app.kubernetes.io/name=config-app
```

## Fix (Option A: Create the missing objects)

```bash
kubectl -n exercise-namespace create configmap missing-config --from-literal=config.txt="hello"

kubectl -n exercise-namespace create secret generic missing-secret --from-literal=api-key="changeme"
```

Then restart/upgrade:

```bash
helm upgrade config-missing . -n exercise-namespace
```

## Fix (Option B: Change the references)

If you already have a ConfigMap/Secret in the namespace, point the chart at them.
Example `fixed-values.yaml`:

```yaml
configMapName: "my-config"
secretName: "my-secret"
```

The repository includes a ready-to-use `fixed-values.yaml` in this directory. This is a reference file to review structure. But it can be applied as is.

### Option 1 (Recommended): GitOps fix (persistent with ArgoCD)

In this environment, ArgoCD tracks:

- **Target Revision**: `argocd-active`
- **Path**: `helm-charts-new/5-config-missing`

So the persistent fix is:

```bash
cd /home/juls/terraform_proxmox/terraform_proxmox
git checkout argocd-active

# edit: helm-charts-new/5-config-missing/values.yaml
git add helm-charts-new/5-config-missing/values.yaml
git commit -m "fix(config-missing): reference valid config/secret"
git push origin argocd-active
```

Then in ArgoCD, sync app `config-missing-helm` (or wait for auto-sync).

### Option 2: Run from laptop over SSH (no local Helm required, temporary override)

```bash
tar -cf - . \
| ssh root@192.168.122.100 '
  set -e
  kubectl get ns exercise-namespace >/dev/null 2>&1 || kubectl create ns exercise-namespace
  tmp=$(mktemp -d)
  tar -xf - -C "$tmp"
  helm template config-missing "$tmp" -f "$tmp/fixed-values.yaml" \
    | kubectl apply -n exercise-namespace -f -
  rm -rf "$tmp"
'
```
