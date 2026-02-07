# Exercise 06: Helm Rollback

Learn how to recover from bad Helm releases using rollback.

## Scenario

Your team deployed a working application using Helm. A developer pushed an update that broke the application. You need to:
1. Identify the broken release
2. Check release history
3. Rollback to the previous working version

## Prerequisites

- Helm installed on control plane
- Understanding of Helm releases
- Basic kubectl knowledge

## Setup

SSH to the control plane:
```bash
ssh root@192.168.122.100
```

## Initial Deployment (Working Version)

Deploy the initial working version:
```bash
# Create namespace
kubectl create namespace exercise-06

# Install initial working version
helm install webapp /root/tabletop-exercises/helm-charts/broken-service \
  -n exercise-06 \
  --set image.repository=hashicorp/http-echo \
  --set image.tag=latest \
  --set service.port=80 \
  --set service.targetPort=8080 \
  --set replicaCount=2

# Verify it works
kubectl get pods -n exercise-06
kubectl port-forward svc/webapp-broken-service 8080:80 -n exercise-06
# In another terminal: curl localhost:8080
```

## The Problem (Bad Upgrade)

Someone upgraded the release with wrong configuration:
```bash
# This breaks the application!
helm upgrade webapp /root/tabletop-exercises/helm-charts/broken-service \
  -n exercise-06 \
  --set service.targetPort=9090 \
  --set image.tag=nonexistent-version

# Now the service is broken!
```

## Your Task

1. **Verify the application is broken**
2. **Check Helm release history**
3. **Identify the working revision**
4. **Rollback to the working version**
5. **Verify the application works again**

## Hints

<details>
<summary>Hint 1: Check release history</summary>

```bash
helm history webapp -n exercise-06
```

Look for:
- REVISION numbers
- STATUS (deployed, superseded)
- DESCRIPTION
</details>

<details>
<summary>Hint 2: Check what changed</summary>

```bash
# Get values from current revision
helm get values webapp -n exercise-06

# Get values from previous revision
helm get values webapp -n exercise-06 --revision 1
```
</details>

<details>
<summary>Hint 3: Rollback command</summary>

```bash
helm rollback webapp [REVISION] -n exercise-06
```

Replace [REVISION] with the working revision number.
</details>

## Expected Behavior

**Before rollback:**
- Pods may be CrashLooping or ImagePullBackOff
- Service endpoints don't work
- `curl` to service fails

**After successful rollback:**
- Pods are Running
- Service works correctly
- `curl` to service returns response

## Learning Objectives

✅ Understand Helm release revisions  
✅ Use `helm history` to view release history  
✅ Compare configuration between revisions  
✅ Perform rollback to previous working state  
✅ Verify rollback success  

## Cleanup

```bash
helm uninstall webapp -n exercise-06
kubectl delete namespace exercise-06
```

## Time Estimate

15-20 minutes
