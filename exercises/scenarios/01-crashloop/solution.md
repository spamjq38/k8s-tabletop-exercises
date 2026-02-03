# Solution: Memory Limit Mayhem

## Quick Answer

The application is being OOMKilled (Out Of Memory Killed) because the memory limit (50Mi) is far too low for its actual needs (128Mi).

**Fix:** Increase memory limit to at least 256Mi in values.yaml

---

## Detailed Step-by-Step Solution

### Step 1: Observe the Problem

```bash
kubectl get pods -n exercise-01
```

**Expected Output:**
```
NAME                          READY   STATUS             RESTARTS   AGE
memory-app-5d7f8b4c9d-xyz12   0/1     CrashLoopBackOff   5          3m
```

**Key Indicators:**
- STATUS: `CrashLoopBackOff` - Pod is crashing and Kubernetes is backing off on restarts
- RESTARTS: Increasing number - Pod keeps trying to start and failing
- READY: 0/1 - Container is not ready

### Step 2: Get Detailed Information

```bash
kubectl describe pod <pod-name> -n exercise-01
```

**Look for these key sections:**

```yaml
State:          Waiting
  Reason:       CrashLoopBackOff
Last State:     Terminated
  Reason:       OOMKilled
  Exit Code:    137
```

**Critical Information:**
- `OOMKilled` - The container was killed due to Out Of Memory
- `Exit Code 137` - Standard exit code for OOM kills (128 + 9 SIGKILL)

**Also check the Events section:**
```
Events:
  Type     Reason     Age                   Message
  ----     ------     ----                  -------
  Warning  BackOff    2m (x5 over 3m)       Back-off restarting failed container
  Normal   Pulled     1m (x5 over 3m)       Container image pulled successfully
  Warning  Failed     1m (x5 over 3m)       Error: OOMKilled
```

### Step 3: Check the Logs

```bash
kubectl logs <pod-name> -n exercise-01 --previous
```

**Expected Output:**
```
Starting Data Processor v1.0
Initializing memory buffer...
Loading configuration...
Allocating 128Mi for data processing...
Processing data batch 1...
Killed
```

The application was killed mid-operation while trying to use memory.

### Step 4: Identify Current Configuration

```bash
helm get values memory-app -n exercise-01
```

**Current values:**
```yaml
resources:
  limits:
    memory: "50Mi"    # ❌ TOO LOW!
    cpu: "100m"
  requests:
    memory: "50Mi"
    cpu: "100m"
```

**Problem identified:** Application needs 128Mi but limit is only 50Mi!

### Step 5: Calculate Proper Limits

The application logs show it needs 128Mi. Best practices suggest:
- **Requests:** Set to typical usage (128Mi)
- **Limits:** Set 1.5-2x requests to allow for spikes (256Mi)

### Step 6: Create Fixed Values File

Create a file called `fixed-values.yaml`:

```yaml
# fixed-values.yaml
resources:
  limits:
    memory: "256Mi"   # 2x the required memory for safety
    cpu: "200m"       # Slightly increased CPU
  requests:
    memory: "128Mi"   # Actual memory requirement
    cpu: "100m"       # Keep CPU request the same
```

### Step 7: Apply the Fix

```bash
helm upgrade memory-app helm-charts/memory-hog \
  -n exercise-01 \
  -f fixed-values.yaml
```

**Expected Output:**
```
Release "memory-app" has been upgraded. Happy Helming!
NAME: memory-app
LAST DEPLOYED: [timestamp]
NAMESPACE: exercise-01
STATUS: deployed
REVISION: 2
```

### Step 8: Verify the Fix

```bash
# Watch pods restart with new configuration
kubectl get pods -n exercise-01 -w
```

**Wait for:**
```
NAME                          READY   STATUS    RESTARTS   AGE
memory-app-7c8d9f5b6a-abc34   1/1     Running   0          30s
```

**Verification checklist:**
```bash
# 1. Pod is running
kubectl get pods -n exercise-01

# 2. No restarts
kubectl get pods -n exercise-01
# Look for RESTARTS = 0

# 3. Check logs for success
kubectl logs <new-pod-name> -n exercise-01

# 4. Verify resource allocation
kubectl describe pod <new-pod-name> -n exercise-01 | grep -A 5 "Limits"
```

**Expected healthy output:**
```
Limits:
  cpu:     200m
  memory:  256Mi
Requests:
  cpu:     100m
  memory:  128Mi
```

### Step 9: Confirm Stability

```bash
# Wait 2 minutes and check again
sleep 120
kubectl get pods -n exercise-01
```

**Success criteria:**
- STATUS: Running
- RESTARTS: 0
- READY: 1/1
- AGE: > 2m

---

## Root Cause Analysis

### What Went Wrong?

1. **Incorrect resource limits** - Memory limit set to 50Mi when app needs 128Mi
2. **No testing in production-like environment** - Dev had no limits, masked the issue
3. **Assumption-based configuration** - Limits set arbitrarily without profiling

### Why Did This Happen?

```
Application needs: 128Mi memory
Limit configured:  50Mi memory
Result: OOMKilled when app tries to allocate memory
Exit code: 137 (128 + SIGKILL)
Pod status: CrashLoopBackOff
```

### The Fix Explained

**Before:**
```yaml
limits:
  memory: "50Mi"    # Application killed when exceeding this
```

**After:**
```yaml
requests:
  memory: "128Mi"   # Guaranteed memory allocation
limits:
  memory: "256Mi"   # Hard limit (2x requests for headroom)
```

**Why 256Mi and not just 128Mi?**
- Applications don't use exactly the same memory every time
- Spikes in data volume can increase memory usage
- Better to have headroom than OOMKill in production
- 2x requests is a common best practice

---

## Key Lessons

### 1. Understanding Resource Limits

**Requests:**
- Memory the pod is *guaranteed* to get
- Used by scheduler to place pods on nodes
- Pod won't be scheduled if node doesn't have enough

**Limits:**
- Maximum memory pod can use
- Exceeding this causes OOMKill
- Should be higher than requests for flexibility

### 2. Reading OOMKill Signals

**Exit Code 137:**
```
137 = 128 + 9
128 = Base value for signal exit codes
9 = SIGKILL
```

**Common OOM indicators:**
- Status: `CrashLoopBackOff`
- Last State Reason: `OOMKilled`
- Exit Code: 137
- Events: "OOMKilled" warnings

### 3. Proper Resource Sizing

**How to determine correct values:**

1. **Development profiling:**
   ```bash
   kubectl top pod <pod-name>
   ```

2. **Production monitoring:**
   - Monitor actual usage over time
   - Account for peak loads
   - Add safety margin

3. **Load testing:**
   - Test with realistic data volumes
   - Simulate peak conditions
   - Measure maximum usage

4. **Best practice ratios:**
   - Limits = 1.5x to 2x requests
   - Never set limits too close to actual usage
   - Always test in staging first

---

## Alternative Solutions

### Option 1: Remove Limits Entirely (Not Recommended)

```yaml
resources:
  requests:
    memory: "128Mi"
  # No limits
```

**Pros:** Pod can use as much memory as needed  
**Cons:** Can cause node instability, affects other pods

### Option 2: Vertical Pod Autoscaler (Advanced)

Install VPA to automatically adjust resource requests:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: memory-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: memory-app
  updatePolicy:
    updateMode: "Auto"
```

**Pros:** Automatically adjusts resources  
**Cons:** Requires VPA installation, more complex

---

## Prevention Strategies

### 1. Pre-Production Testing

Always test resource limits in staging:

```bash
# Deploy with prod-like limits in staging first
helm install app ./chart -f production-values.yaml -n staging
# Monitor for 24 hours
kubectl top pods -n staging
```

### 2. Resource Requests = Typical Usage

Set requests based on actual profiling:

```bash
# Profile the app in dev
kubectl top pod <pod> --containers -n dev
# Set requests to average usage
# Set limits to peak usage + 50%
```

### 3. Monitoring and Alerts

Set up alerts for OOMKills:

```yaml
# Example Prometheus alert
- alert: PodOOMKilled
  expr: sum(rate(kube_pod_container_status_terminated_reason{reason="OOMKilled"}[5m])) > 0
  annotations:
    summary: "Pod was OOMKilled"
```

### 4. Documentation

Document resource requirements in your chart:

```yaml
# values.yaml
resources:
  limits:
    memory: "256Mi"   # Tested with 500MB data files
    cpu: "200m"
  requests:
    memory: "128Mi"   # Average usage: 120Mi
    cpu: "100m"
```

---

## Testing Your Understanding

### Quiz Questions

1. What does exit code 137 indicate?
2. What's the difference between requests and limits?
3. Why set limits higher than requests?
4. How would you profile an application's actual memory usage?

### Practice Exercises

1. **Modify the scenario:**
   - Set memory limit to 100Mi - does it still crash?
   - Set memory limit to 1024Mi - is this wasteful?
   - Set CPU limit very low - what happens?

2. **Create your own scenario:**
   - Build a chart with CPU constraints instead
   - Create a pod that needs more memory under load
   - Add readiness probes that fail with low resources

---

## Additional Resources

- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Quality of Service (QoS) Classes](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)
- [Debugging OOMKilled Containers](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)

---

## Congratulations! 🎉

You've successfully:
- ✅ Diagnosed a CrashLoopBackOff issue
- ✅ Identified OOMKilled as the root cause
- ✅ Fixed the issue using Helm
- ✅ Understood resource management concepts

**Ready for the next challenge?** Move on to [Scenario 2: The Unreachable Service](../02-service-port/README.md)
