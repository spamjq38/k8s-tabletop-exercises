# Scenario 3: Image Pull Nightmare

**Difficulty:** ⭐ Beginner  
**Estimated Time:** 15-20 minutes  
**Skills Practiced:** 
- ImagePullBackOff troubleshooting
- Image tag debugging
- Registry authentication
- Container image investigation

## Problem Statement

The development team is trying to deploy a new microservice, but the pods keep failing with `ImagePullBackOff` errors. They've tried several different approaches but can't figure out why the images won't pull.

Your task is to:
1. Identify why images are failing to pull
2. Determine the root causes (there are multiple issues!)
3. Fix each problem
4. Verify all pods are running successfully

## Background

This scenario includes three common image-related issues:
- **Wrong image tag** - Non-existent version specified
- **Typo in image name** - Misspelled repository name
- **Private registry** - Missing credentials (bonus challenge)

## Success Criteria

✅ All three deployments are in `Running` state  
✅ No `ImagePullBackOff` or `ErrImagePull` errors  
✅ You understand each type of image problem  
✅ Pods pass readiness checks

## Setup

1. **Create a dedicated namespace:**
   ```bash
   kubectl create namespace exercise-03
   kubens exercise-03
   ```

2. **Deploy the broken applications:**
   ```bash
   cd /root/tabletop-exercises/scenarios/03-imagepull
   kubectl apply -f broken-deployments.yaml
   ```

3. **Wait 30 seconds for the issues to manifest:**
   ```bash
   sleep 30
   kubectl get pods -n exercise-03
   ```

## Your Mission

Use the troubleshooting workflow to diagnose and fix each issue:

### Phase 1: Observation (5 minutes)
- Check pod status
- Look at events
- Identify which images are failing

### Phase 2: Diagnosis (5 minutes)
- Examine pod descriptions
- Check image names and tags
- Identify the specific errors

### Phase 3: Resolution (5 minutes)
- Fix the wrong tag
- Correct the typo
- Verify successful pulls

## Hints

<details>
<summary>Hint 1: Where to start?</summary>

Always start with `kubectl get pods` to see which ones have ImagePullBackOff. Then use `kubectl describe pod <name>` to see the specific error.

</details>

<details>
<summary>Hint 2: What commands show image issues?</summary>

```bash
kubectl describe pod <pod-name> | grep -A 10 Events
kubectl describe pod <pod-name> | grep Image
```

</details>

<details>
<summary>Hint 3: Common image pull errors</summary>

- `manifest unknown` = tag doesn't exist
- `not found` = repository name is wrong
- `unauthorized` = need authentication
- `pull access denied` = private image without credentials

</details>

<details>
<summary>Hint 4: How to fix?</summary>

You need to edit the deployment to fix the image reference:
```bash
kubectl edit deployment <deployment-name> -n exercise-03
# Or use kubectl set image
kubectl set image deployment/<name> <container-name>=<correct-image>
```

</details>

<details>
<summary>Hint 5: What are the correct images?</summary>

- Wrong tag: Change from `nginx:99.99.99` to `nginx:latest` or `nginx:1.27`
- Typo: Change from `ngimx` to `nginx`
- For private registry (bonus): You'd need to create an image pull secret

</details>

## Common Commands

```bash
# Check pod status
kubectl get pods -n exercise-03

# Describe pod to see events
kubectl describe pod <pod-name> -n exercise-03

# Check specific events
kubectl get events -n exercise-03 --sort-by='.lastTimestamp'

# Edit deployment
kubectl edit deployment <name> -n exercise-03

# Set new image
kubectl set image deployment/<name> container-name=nginx:latest -n exercise-03

# Watch pods recover
kubectl get pods -n exercise-03 -w

# Check image being used
kubectl get pod <name> -n exercise-03 -o jsonpath='{.spec.containers[*].image}'
```

## Learning Objectives

After completing this scenario, you will understand:

1. **ImagePullBackOff** vs **ErrImagePull** - What each means
2. **Image naming** - registry/repository:tag format
3. **Tag importance** - Why version pinning matters
4. **Event inspection** - How to read Kubernetes events
5. **Quick fixes** - Using kubectl set image vs editing deployments

## Cleanup

```bash
kubectl delete namespace exercise-03
```

## Next Steps

- Try Scenario 4: Configuration Chaos
- Learn about image pull secrets for private registries
- Explore image scanning and security
