# broken-service Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Service routes traffic to the wrong `targetPort`, so requests fail even though the Pod is running.

## The Problem

- The container runs `python -m http.server 8080` (listening on **8080**)
- `values.yaml` sets `service.targetPort: 9090`
- Result: the Service sends traffic to a port where nothing is listening

## How to Reproduce

`exercise-namespace` below is a Kubernetes namespace name (not a local repo folder). It is created automatically by `--create-namespace`.

Commands below must be run from a machine where this chart directory exists. If you run from the control plane, sync/copy `broken-service/` there first.
Commands below must be run from a machine where this chart directory exists.

```bash
helm install broken-service . -n exercise-namespace --create-namespace
kubectl get svc,pods -n exercise-namespace
kubectl describe svc -n exercise-namespace broken-app

# Try reaching the service
kubectl -n exercise-namespace port-forward svc/broken-app 8080:80
curl -v http://127.0.0.1:8080/
```

## Fix

Make `service.targetPort` match the container port (`8080`). Example `fixed-values.yaml`:

```yaml
service:
  targetPort: 8080
```

Apply the fix:

The repository includes a ready-to-use `fixed-values.yaml` in this directory. This is a reference file to review structure. But it can be applied as is.

### Option 1 (Recommended): GitOps fix (persistent with ArgoCD)

In this environment, ArgoCD tracks:

- **Target Revision**: `argocd-active`
- **Path**: `helm-charts-new/broken-service`

So the persistent fix is:

```bash
cd /home/juls/terraform_proxmox/terraform_proxmox
git checkout argocd-active

# edit: helm-charts-new/broken-service/values.yaml
git add helm-charts-new/broken-service/values.yaml
git commit -m "fix(broken-service): set targetPort to 8080"
git push origin argocd-active
```

Then in ArgoCD, sync app `broken-service-helm` (or wait for auto-sync).

### Option 2: Run from laptop over SSH (no local Helm required, temporary override)

```bash
tar -cf - . \
| ssh root@192.168.122.100 '
  set -e
  kubectl get ns exercise-namespace >/dev/null 2>&1 || kubectl create ns exercise-namespace
  tmp=$(mktemp -d)
  tar -xf - -C "$tmp"
  helm template broken-service "$tmp" -f "$tmp/fixed-values.yaml" \
    | kubectl apply -n exercise-namespace -f -
  rm -rf "$tmp"
'
```
