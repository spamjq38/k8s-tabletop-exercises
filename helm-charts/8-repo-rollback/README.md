# 8-repo-rollback Helm Chart

## Purpose

This exercise teaches **Helm repo versioning + rollback**:

1. Build a small **local Helm repo** (packaged charts + `index.yaml`)
2. Install version `0.1.0` from that repo
3. Publish a **broken** version `0.2.0` to the same repo and upgrade
4. Use `helm history` + `helm rollback` (or pin `--version`) to recover

## What You Start With (v0.1.0)

- A simple BusyBox Deployment that logs a message and stays running.
- It is **healthy** by default.

## How to Reproduce (create a local repo, then upgrade to a broken version)

### 1) Package v0.1.0 into a local repo directory

From this chart directory:

```bash
cd helm-charts-new/8-repo-rollback

mkdir -p /tmp/helm-local-repo
helm package . -d /tmp/helm-local-repo
helm repo index /tmp/helm-local-repo
helm repo add local-exercises file:///tmp/helm-local-repo
helm repo update
```

### 2) Install from the repo

```bash
helm install repo-rollback local-exercises/repo-rollback \
  --version 0.1.0 \
  -n exercise-08 --create-namespace

kubectl get pods -n exercise-08 -w
kubectl logs -n exercise-08 deploy/repo-rollback-app
```

### 3) Publish a broken v0.2.0 and upgrade

Make the chart intentionally broken:

- Edit `Chart.yaml`: set `version: 0.2.0`
- Edit `values.yaml` and change `containerCommand` to an invalid binary:

```yaml
containerCommand:
  - /bin/invalid-command
```

Then package and re-index the repo:

```bash
helm package . -d /tmp/helm-local-repo
helm repo index /tmp/helm-local-repo --merge /tmp/helm-local-repo/index.yaml
helm repo update
```

Upgrade to the new version:

```bash
helm upgrade repo-rollback local-exercises/repo-rollback \
  --version 0.2.0 \
  -n exercise-08

kubectl get pods -n exercise-08 -w
kubectl describe pod -n exercise-08 -l app.kubernetes.io/instance=repo-rollback
kubectl logs -n exercise-08 -l app.kubernetes.io/instance=repo-rollback --previous
```

Expected outcome: the Pod goes into `CrashLoopBackOff`.

## Rollback

### Option A: Roll back to the previous Helm revision (most common)

```bash
helm history repo-rollback -n exercise-08
helm rollback repo-rollback 1 -n exercise-08

kubectl get pods -n exercise-08 -w
kubectl logs -n exercise-08 deploy/repo-rollback-app
```

### Option B: Pin the chart version and upgrade back

This re-applies a known-good chart version from the repo.

```bash
helm upgrade repo-rollback local-exercises/repo-rollback \
  --version 0.1.0 \
  -n exercise-08
```

## Cleanup

```bash
helm uninstall repo-rollback -n exercise-08
kubectl delete ns exercise-08
```
