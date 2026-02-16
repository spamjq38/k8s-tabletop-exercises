# 2-imagepull Helm Chart

## Purpose

This chart is **intentionally broken** for training. The Pod enters `ImagePullBackOff` because the image tag does not exist.

## The Problem

- `values.yaml` uses `image.repository: nginx`
- But `image.tag` is set to a non-existent tag (`non-existent-tag-xyz123`)
- The node cannot pull the image, so the Pod never starts

## How to Reproduce

```bash
helm install imagepull . -n exercise-01 --create-namespace
kubectl get pods -n exercise-01 -w
kubectl describe pod -n exercise-01 -l app.kubernetes.io/name=imagepull-app
```

## Fix

Set `image.tag` to a real tag (for example `latest`). Example `fixed-values.yaml`:

```yaml
image:
  repository: nginx
  tag: "latest"
```

Apply the fix:

```bash
helm upgrade imagepull . -n exercise-01 -f fixed-values.yaml
```
