# Solution: Helm Rollback Exercise

## Step-by-Step Solution

### Step 1: Verify Application is Broken

```bash
# Check pod status
kubectl get pods -n exercise-06
```

**Expected output:**
```
NAME                                      READY   STATUS             RESTARTS
webapp-broken-service-xxx                 0/1     ImagePullBackOff   0
```

```bash
# Check service
kubectl get svc -n exercise-06
```

### Step 2: Check Helm Release History

```bash
helm history webapp -n exercise-06
```

**Expected output:**
```
REVISION  UPDATED                   STATUS      CHART                 DESCRIPTION
1         Fri Feb  7 10:00:00 2026  superseded  broken-service-0.1.0  Install complete
2         Fri Feb  7 10:05:00 2026  deployed    broken-service-0.1.0  Upgrade complete
```

**Analysis:**
- Revision 1: Initial install (superseded - replaced by newer version)
- Revision 2: Current broken upgrade (deployed - currently active)

### Step 3: Compare Configurations

```bash
# Check current (broken) values
helm get values webapp -n exercise-06
```

**Output:**
```yaml
image:
  tag: nonexistent-version
service:
  targetPort: 9090
```

```bash
# Check previous (working) values
helm get values webapp -n exercise-06 --revision 1
```

**Output:**
```yaml
image:
  repository: hashicorp/http-echo
  tag: latest
replicaCount: 2
service:
  port: 80
  targetPort: 8080
```

**Problems identified:**
1. Image tag changed to `nonexistent-version` (doesn't exist)
2. Service targetPort changed to `9090` (app listens on 8080)

### Step 4: Rollback to Working Version

```bash
# Rollback to revision 1 (the working version)
helm rollback webapp 1 -n exercise-06
```

**Expected output:**
```
Rollback was a success! Happy Helming!
```

**Alternatively, rollback to previous revision:**
```bash
# Rollback to previous revision (without specifying number)
helm rollback webapp -n exercise-06
```

### Step 5: Verify Rollback Success

```bash
# Check pod status
kubectl get pods -n exercise-06
```

**Expected output:**
```
NAME                                      READY   STATUS    RESTARTS   AGE
webapp-broken-service-xxx                 1/1     Running   0          30s
webapp-broken-service-yyy                 1/1     Running   0          30s
```

```bash
# Check release history
helm history webapp -n exercise-06
```

**Expected output:**
```
REVISION  UPDATED                   STATUS      CHART                 DESCRIPTION
1         Fri Feb  7 10:00:00 2026  superseded  broken-service-0.1.0  Install complete
2         Fri Feb  7 10:05:00 2026  superseded  broken-service-0.1.0  Upgrade complete
3         Fri Feb  7 10:10:00 2026  deployed    broken-service-0.1.0  Rollback to 1
```

**Notice:**
- Revision 3 is created (rollback creates new revision)
- Description shows "Rollback to 1"
- Revision 2 is now superseded

```bash
# Test the service
kubectl port-forward svc/webapp-broken-service 8080:80 -n exercise-06
```

In another terminal:
```bash
curl localhost:8080
```

**Expected:** Service responds successfully!

## Key Concepts Learned

### Helm Revisions
- Each `helm install`, `helm upgrade`, or `helm rollback` creates a new revision
- Rollback doesn't delete bad revisions - it creates a new one with old config
- History is preserved for auditing

### Helm History Commands

```bash
# View release history
helm history RELEASE_NAME -n NAMESPACE

# Get all details of specific revision
helm get all RELEASE_NAME -n NAMESPACE --revision REVISION_NUMBER

# Get only values
helm get values RELEASE_NAME -n NAMESPACE --revision REVISION_NUMBER

# Get only manifest
helm get manifest RELEASE_NAME -n NAMESPACE --revision REVISION_NUMBER
```

### Rollback Options

```bash
# Rollback to previous revision
helm rollback RELEASE_NAME -n NAMESPACE

# Rollback to specific revision
helm rollback RELEASE_NAME REVISION_NUMBER -n NAMESPACE

# Dry run (test without actually rolling back)
helm rollback RELEASE_NAME REVISION_NUMBER -n NAMESPACE --dry-run

# Force rollback (replace resources)
helm rollback RELEASE_NAME REVISION_NUMBER -n NAMESPACE --force

# Clean up on failed rollback
helm rollback RELEASE_NAME REVISION_NUMBER -n NAMESPACE --cleanup-on-fail
```

## Common Mistakes

❌ **Trying to rollback without checking history first**
- Always check `helm history` to identify the correct revision

❌ **Assuming rollback deletes the bad revision**
- Rollback creates a new revision; history is preserved

❌ **Not verifying the rollback worked**
- Always check pods and test the application after rollback

❌ **Rolling back to wrong revision**
- Compare values between revisions to ensure you're rolling back to the right one

## Advanced: Rollback via Git (GitOps)

If using ArgoCD with Helm, you can rollback by reverting Git commits:

```bash
# In your Git repo
git log --oneline  # Find the good commit

git revert <bad-commit-hash>
git push

# ArgoCD will automatically sync and redeploy the old version
```

## Cleanup

```bash
helm uninstall webapp -n exercise-06
kubectl delete namespace exercise-06
```

## Summary

**Rollback workflow:**
1. `helm history` → Identify revisions
2. `helm get values --revision` → Compare configurations  
3. `helm rollback RELEASE REVISION` → Rollback to working version
4. Verify pods and functionality

**Remember:** Rollback is safe - it doesn't delete history, just creates a new revision with old configuration.
