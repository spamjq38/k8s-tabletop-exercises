# 8-repo-rollback Helm Chart

## Purpose

This exercise teaches **Helm repo versioning + rollback**:

1. Build a small **local Helm repo** (packaged charts + `index.yaml`)
2. Install version `0.1.0` from that repo
3. Publish a **broken** version `0.2.0` to the same repo and upgrade
4. Use `helm history` + `helm rollback` (or pin `--version`) to recover

## Before You Start: Pick Your Rollback Mode

There are two valid rollback modes in this repository:

1. **Standalone Helm mode (recommended for learning Helm rollback):**
  You run `helm install/upgrade/rollback` directly. This creates Helm release
  history and makes `helm history` + `helm rollback` work.
2. **ArgoCD-managed mode (default deploy flow):**
  ArgoCD renders and applies manifests. In this mode, a Helm release object is
  usually not created, so `helm history repo-rollback ...` can return
  `release: not found`.

If your goal is specifically to learn Helm rollback mechanics, use **Standalone Helm mode** below.

## What You Start With (v0.1.0)

- A simple BusyBox Deployment that logs a message and stays running.
- It is **healthy** by default.

## How to Reproduce (create a local repo, then upgrade to a broken version)

`exercise-repo-rollback` below is the namespace used by this exercise in this repo's ArgoCD flow.

### Why this sequence works

1. You package chart versions to simulate a real chart repository lifecycle.
2. You install a known-good release first, so Helm stores revision history.
3. You upgrade to a broken revision, so there is something meaningful to roll back from.
4. You inspect history and roll back to a previous revision to restore service.

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

Why these commands:

1. `helm package` creates a versioned chart archive (`.tgz`).
2. `helm repo index` creates/updates `index.yaml`, which is what Helm queries.
3. `helm repo add ... file://` registers your local repo as an install source.
4. `helm repo update` refreshes local metadata cache.

### 2) Install from the repo

```bash
helm install repo-rollback local-exercises/repo-rollback \
  --version 0.1.0 \
  -n exercise-repo-rollback --create-namespace

kubectl get pods -n exercise-repo-rollback -w
kubectl logs -n exercise-repo-rollback deploy/repo-rollback-app
```

Why these commands:

1. `helm install ... --version 0.1.0` creates **revision 1** in Helm history.
2. `kubectl get/logs` confirms baseline is healthy before introducing failure.

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

Why these commands:

1. Repackaging with `version: 0.2.0` creates a new installable chart revision.
2. `--merge` preserves existing index entries and adds the new one.
3. `helm repo update` ensures Helm can resolve the new version metadata.

Upgrade to the new version:

```bash
helm upgrade repo-rollback local-exercises/repo-rollback \
  --version 0.2.0 \
  -n exercise-repo-rollback

kubectl get pods -n exercise-repo-rollback -w
kubectl describe pod -n exercise-repo-rollback -l app.kubernetes.io/instance=repo-rollback
kubectl logs -n exercise-repo-rollback -l app.kubernetes.io/instance=repo-rollback --previous
```

Expected outcome: the Pod goes into `CrashLoopBackOff`.

## Rollback

Important: In this repository's default flow, this chart is applied by ArgoCD as an Application.
That means there is usually no Helm release object named `repo-rollback` for `helm history` to inspect.
If `helm history repo-rollback -n exercise-repo-rollback` returns `release: not found`, use the
ArgoCD rollback flow below.

### Why learners were seeing `release: not found`

1. The default deploy script creates an ArgoCD Application (`repo-rollback-helm`).
2. ArgoCD applies manifests from Git; it does not guarantee a Helm release record
  named `repo-rollback` in the namespace.
3. Without a Helm release record, `helm history` and `helm rollback` cannot operate.

### How this README fixes that confusion

1. It explicitly separates **Standalone Helm rollback** from **ArgoCD rollback**.
2. It explains which commands create Helm history and why they are required.
3. It preserves an ArgoCD rollback path for users staying in default GitOps mode.

### ArgoCD-managed rollback (default in this repo)

Use ArgoCD app history and rollback for `repo-rollback-helm`:

```bash
argocd app history repo-rollback-helm
argocd app rollback repo-rollback-helm <HISTORY_ID>
```

Or trigger rollback by setting a known-good git revision/commit for the Application source.

### Option A: Roll back to the previous Helm revision (most common)

This option works when you installed the chart directly with `helm install`.

```bash
helm history repo-rollback -n exercise-repo-rollback
helm rollback repo-rollback 1 -n exercise-repo-rollback

kubectl get pods -n exercise-repo-rollback -w
kubectl logs -n exercise-repo-rollback deploy/repo-rollback-app
```

Why these commands:

1. `helm history` shows revision IDs so you can pick a valid rollback target.
2. `helm rollback ... 1` reapplies manifest state from revision 1.
3. `kubectl get/logs` validates recovery and confirms the fix worked.

### Option B: Pin the chart version and upgrade back

This re-applies a known-good chart version from the repo.

```bash
helm upgrade repo-rollback local-exercises/repo-rollback \
  --version 0.1.0 \
  -n exercise-repo-rollback
```

## Cleanup

```bash
helm uninstall repo-rollback -n exercise-repo-rollback
kubectl delete ns exercise-repo-rollback
```
