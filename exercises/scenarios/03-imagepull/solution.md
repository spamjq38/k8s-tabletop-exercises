# Solution: Image Pull Nightmare

## Step-by-Step Solution

### Step 1: Identify the Problems

```bash
# Check pod status
kubectl get pods -n exercise-03

# You should see:
# NAME                               READY   STATUS             RESTARTS   AGE
# wrong-tag-app-xxx                  0/1     ImagePullBackOff   0          1m
# typo-app-xxx                       0/1     ErrImagePull       0          1m
# missing-repo-app-xxx               0/1     ImagePullBackOff   0          1m
```

### Step 2: Diagnose Each Issue

**Problem 1: Wrong Tag**
```bash
kubectl describe pod wrong-tag-app-xxx -n exercise-03 | grep -A 5 Events
# Error: manifest for nginx:99.99.99 not found
```

**Problem 2: Typo in Image Name**
```bash
kubectl describe pod typo-app-xxx -n exercise-03 | grep -A 5 Events
# Error: repository ngimx not found
```

**Problem 3: Non-existent Repository**
```bash
kubectl describe pod missing-repo-app-xxx -n exercise-03 | grep -A 5 Events
# Error: repository thisrepodoesnotexist/fake-image not found
```

### Step 3: Fix Each Deployment

**Fix #1: Update wrong tag to valid version**
```bash
kubectl set image deployment/wrong-tag-app nginx=nginx:1.27 -n exercise-03
# Or
kubectl edit deployment wrong-tag-app -n exercise-03
# Change: image: nginx:99.99.99
# To:     image: nginx:1.27
```

**Fix #2: Correct the typo**
```bash
kubectl set image deployment/typo-app web=nginx:latest -n exercise-03
# Or
kubectl edit deployment typo-app -n exercise-03
# Change: image: ngimx:latest
# To:     image: nginx:latest
```

**Fix #3: Use a real image**
```bash
kubectl set image deployment/missing-repo-app app=busybox:latest -n exercise-03
# Or
kubectl edit deployment missing-repo-app -n exercise-03
# Change: image: thisrepodoesnotexist/fake-image:v1.0
# To:     image: busybox:latest
```

### Step 4: Verify the Fixes

```bash
# Watch pods come up
kubectl get pods -n exercise-03 -w

# All should be Running
kubectl get pods -n exercise-03
# NAME                               READY   STATUS    RESTARTS   AGE
# wrong-tag-app-xxx                  1/1     Running   0          30s
# typo-app-xxx                       1/1     Running   0          25s
# missing-repo-app-xxx               1/1     Running   0          20s
```

## What We Learned

### Error Types

1. **`manifest unknown` / `manifest for ... not found`**
   - The tag doesn't exist in the registry
   - Fix: Use a valid tag

2. **`repository not found`**
   - Typo in image name or registry path
   - Fix: Correct the spelling

3. **`pull access denied` / `unauthorized`**
   - Private image without credentials
   - Fix: Create and attach imagePullSecret

### Best Practices

1. **Always pin specific versions** in production:
   ```yaml
   image: nginx:1.27.3  # ✅ Good
   image: nginx:latest  # ❌ Avoid in production
   ```

2. **Verify images exist** before deploying:
   ```bash
   docker pull nginx:1.27.3
   # Or check on Docker Hub
   ```

3. **Use image pull policies**:
   ```yaml
   imagePullPolicy: IfNotPresent  # Default, good for most cases
   imagePullPolicy: Always        # Always check for updates
   imagePullPolicy: Never         # Only use local images
   ```

## Advanced: Private Registry (Bonus)

If you want to practice with private registries:

```bash
# Create a docker registry secret
kubectl create secret docker-registry my-registry-secret \
  --docker-server=registry.example.com \
  --docker-username=myuser \
  --docker-password=mypass \
  --docker-email=user@example.com \
  -n exercise-03

# Reference it in deployment
spec:
  imagePullSecrets:
  - name: my-registry-secret
  containers:
  - name: app
    image: registry.example.com/private/myapp:v1.0
```

## Troubleshooting Commands Reference

```bash
# View all events sorted by time
kubectl get events -n exercise-03 --sort-by='.lastTimestamp'

# Check what image a pod is trying to use
kubectl get pod <name> -n exercise-03 -o yaml | grep image:

# See image pull progress
kubectl describe pod <name> -n exercise-03 | grep -A 20 Events

# Force a new rollout after fixing
kubectl rollout restart deployment/<name> -n exercise-03

# Check deployment image
kubectl get deployment <name> -n exercise-03 -o jsonpath='{.spec.template.spec.containers[0].image}'
```

## Cleanup

```bash
kubectl delete namespace exercise-03
```
