# Kubernetes Troubleshooting Playbook

## Purpose

This playbook provides a systematic approach to diagnosing and resolving common Kubernetes issues. Use this as a reference during tabletop exercises and real-world incidents.

---

## The Universal Troubleshooting Workflow

Follow this methodology for ANY Kubernetes issue:

```
1. OBSERVE   → What is happening?
2. DESCRIBE  → Get detailed information
3. LOGS      → Check application output
4. DEBUG     → Interactive investigation
5. FIX       → Apply solution
6. VERIFY    → Confirm resolution
```

---

## Quick Reference Matrix

| Symptom | Likely Cause | First Command |
|---------|--------------|---------------|
| `Pending` | Scheduling issue | `kubectl describe pod` |
| `ImagePullBackOff` | Wrong image/tag | `kubectl describe pod` |
| `CrashLoopBackOff` | App crash or OOM | `kubectl logs --previous` |
| `Error` | Failed command | `kubectl logs` |
| `Running` but not working | Config/Network issue | `kubectl exec` or debug pod |
| Service timeout | Port mismatch | `kubectl describe svc` + endpoints |
| 0/1 Ready | Health probe failing | `kubectl describe pod` |

---

## 1. Pod Issues

### Pending Status

**Symptoms:**
- Pod stuck in `Pending` state
- Never starts running

**Diagnostic Steps:**

```bash
# 1. Check pod details
kubectl describe pod <pod-name> -n <namespace>

# Look for events like:
# - "0/3 nodes available: insufficient memory"
# - "0/3 nodes have matching node selector"
# - "pod has unbound immediate PersistentVolumeClaims"

# 2. Check node resources
kubectl describe nodes
kubectl top nodes

# 3. Check persistent volume claims
kubectl get pvc -n <namespace>
```

**Common Causes:**

| Cause | Event Message | Solution |
|-------|---------------|----------|
| Insufficient resources | `insufficient cpu/memory` | Reduce requests or add nodes |
| Node selector mismatch | `node(s) didn't match selector` | Fix node selector or label nodes |
| Taints/tolerations | `node(s) had taint that pod didn't tolerate` | Add toleration or remove taint |
| PVC not bound | `pod has unbound PVC` | Check PV availability |

**Example Fix:**

```yaml
# If node selector doesn't match
spec:
  nodeSelector:
    disktype: ssd  # ❌ No nodes have this label

# Fix: Remove or use correct label
spec:
  nodeSelector:
    kubernetes.io/os: linux  # ✅ Valid label
```

---

### ImagePullBackOff

**Symptoms:**
- Status: `ImagePullBackOff` or `ErrImagePull`
- Image cannot be pulled

**Diagnostic Steps:**

```bash
# 1. Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Look for:
# - "Failed to pull image"
# - "repository does not exist"
# - "manifest unknown"
# - "unauthorized"

# 2. Check image name
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[*].image}'

# 3. Try pulling manually (if using Docker)
docker pull <image-name>
```

**Common Causes:**

| Cause | Error Message | Solution |
|-------|---------------|----------|
| Wrong image name | `not found` | Correct image repository |
| Wrong tag | `manifest unknown` | Verify tag exists |
| Private registry auth | `unauthorized` | Add imagePullSecret |
| Typo in name | `no such host` | Fix spelling |
| Registry unavailable | `connection refused` | Check registry status |

**Example Fix:**

```yaml
# Before (wrong tag)
image: nginx:1.99.99  # ❌ Doesn't exist

# After
image: nginx:1.21.3   # ✅ Valid tag
```

---

### CrashLoopBackOff

**Symptoms:**
- Pod starts then crashes repeatedly
- Restart count keeps increasing

**Diagnostic Steps:**

```bash
# 1. Check current logs
kubectl logs <pod-name> -n <namespace>

# 2. Check previous container logs (crashed container)
kubectl logs <pod-name> -n <namespace> --previous

# 3. Describe pod to see exit code
kubectl describe pod <pod-name> -n <namespace>

# Look for:
# - Exit Code: 137 (OOMKilled)
# - Exit Code: 1 (Application error)
# - Exit Code: 0 (Successful exit but restartPolicy)

# 4. Check resource limits
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[*].resources}'
```

**Common Causes:**

| Exit Code | Meaning | Diagnostic |
|-----------|---------|------------|
| 0 | Successful exit | Check restartPolicy, app shouldn't exit |
| 1 | Application error | Check logs for error messages |
| 137 | OOMKilled (128+9) | Increase memory limits |
| 139 | Segmentation fault | App bug, check logs |
| 143 | SIGTERM (128+15) | Graceful shutdown, check why |

**Example Diagnosis:**

```bash
# Check last state
kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState}'

# Output showing OOMKill:
{
  "terminated": {
    "exitCode": 137,
    "reason": "OOMKilled"
  }
}

# Fix: Increase memory
resources:
  limits:
    memory: "256Mi"  # Increased from 50Mi
```

---

## 2. Service and Networking Issues

### Service Not Accessible

**Symptoms:**
- Cannot reach service
- Connection timeout or refused
- curl/wget fails

**Diagnostic Steps:**

```bash
# 1. Check service exists
kubectl get svc <service-name> -n <namespace>

# 2. Describe service
kubectl describe svc <service-name> -n <namespace>

# Look for:
# - Endpoints (should list pod IPs)
# - Ports (port vs targetPort)
# - Selector (must match pod labels)

# 3. Check endpoints
kubectl get endpoints <service-name> -n <namespace>

# Should show: 10.244.1.5:8080,10.244.1.6:8080
# If empty → selector mismatch or no ready pods

# 4. Verify pod labels match selector
kubectl get pods -n <namespace> --show-labels
kubectl get svc <service-name> -n <namespace> -o jsonpath='{.spec.selector}'

# 5. Test with debug pod
kubectl run netshoot --rm -it --image=nicolaka/netshoot -n <namespace> -- bash

# Inside debug pod:
nslookup <service-name>
curl http://<service-name>:<port>
```

**Port Configuration Checklist:**

```yaml
# Deployment
containers:
- ports:
  - containerPort: 8080  # A) Container listens here

# Service
ports:
- port: 80              # B) Service external port
  targetPort: 8080      # C) MUST match (A)
```

**Common Issues:**

| Problem | Symptom | Fix |
|---------|---------|-----|
| Wrong targetPort | Connection refused/timeout | Match targetPort to containerPort |
| Selector mismatch | No endpoints | Fix selector to match pod labels |
| Pods not ready | Empty endpoints | Fix readiness probe or pod issue |
| Wrong port protocol | Connection issues | Match TCP/UDP in service and pod |

---

### DNS Issues

**Symptoms:**
- `nslookup` or `dig` fails
- "could not resolve host"

**Diagnostic Steps:**

```bash
# 1. Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Should be Running

# 2. Test DNS from inside cluster
kubectl run dnstest --rm -it --image=busybox -- nslookup kubernetes.default

# Should resolve to cluster IP

# 3. Check DNS service
kubectl get svc -n kube-system kube-dns

# 4. Examine CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns
```

**DNS Naming Convention:**

```
<service-name>.<namespace>.svc.cluster.local

Examples:
- my-service.default.svc.cluster.local
- webapp.production.svc.cluster.local
- mysql (shorthand in same namespace)
```

---

## 3. Configuration Issues

### ConfigMap/Secret Not Found

**Diagnostic Steps:**

```bash
# 1. Check if ConfigMap exists
kubectl get configmap <name> -n <namespace>

# 2. Verify pod is looking for correct name
kubectl describe pod <pod> -n <namespace>

# Look in Events for:
# - "configmap not found"
# - "secret not found"

# 3. Check namespace
kubectl get configmap --all-namespaces | grep <name>
```

**Common Issues:**
- Wrong namespace
- Typo in name
- ConfigMap created after pod
- Case sensitivity

---

### Environment Variables Missing

**Symptoms:**
- App complains about missing configuration
- Logs show null/undefined variables

**Diagnostic Steps:**

```bash
# 1. Check actual environment in pod
kubectl exec <pod> -n <namespace> -- env

# 2. Compare to expected values
kubectl get pod <pod> -n <namespace> -o jsonpath='{.spec.containers[*].env}'

# 3. If from ConfigMap, verify ConfigMap content
kubectl describe configmap <cm-name> -n <namespace>
```

---

## 4. Resource Issues

### Resource Quota Exceeded

**Symptoms:**
- Pods stay Pending
- Error creating resources

**Diagnostic Steps:**

```bash
# 1. Check resource quotas
kubectl get resourcequota -n <namespace>

# 2. Describe quota
kubectl describe resourcequota -n <namespace>

# Look for: Used vs Hard limits

# 3. Check current resource usage
kubectl top pods -n <namespace>
kubectl describe nodes
```

**Example Output:**

```
Name:       compute-quota
Used:       cpu: 900m, memory: 1.5Gi
Hard:       cpu: 1, memory: 2Gi

# Solution: Either:
# - Delete unused pods
# - Increase quota
# - Reduce resource requests
```

---

## 5. Debugging Techniques

### Interactive Debugging

```bash
# Method 1: Exec into running pod
kubectl exec -it <pod> -n <namespace> -- /bin/sh

# Inside pod:
ps aux                    # Check running processes
netstat -tuln             # Check listening ports
env                       # Check environment variables
cat /etc/resolv.conf      # Check DNS config

# Method 2: Debug ephemeral container (K8s 1.23+)
kubectl debug <pod> -it --image=busybox -n <namespace>

# Method 3: Create debug pod
kubectl run debug --rm -it --image=nicolaka/netshoot -n <namespace> -- /bin/bash

# Test connectivity
curl http://<service>:<port>
nslookup <service>
traceroute <ip>
tcpdump -i any port 8080
```

### Network Debugging Tools

```bash
# Deploy netshoot (comprehensive network tools)
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# Available tools:
curl, wget, httpie       # HTTP testing
nslookup, dig, host      # DNS troubleshooting
ping, traceroute         # Network path
netstat, ss              # Socket stats
tcpdump, ngrep           # Packet capture
iftop                    # Bandwidth monitoring
```

### Reading Events

```bash
# All events in namespace
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Events for specific pod
kubectl describe pod <pod> -n <namespace>

# Watch events in real-time
kubectl get events -n <namespace> --watch

# Filter by type
kubectl get events -n <namespace> --field-selector type=Warning
```

---

## 6. Helm-Specific Troubleshooting

### Release Not Installing

```bash
# 1. Dry-run to see what would be created
helm install <release> <chart> --dry-run --debug

# 2. Render templates locally
helm template <release> <chart> -f values.yaml

# 3. Check for syntax errors
helm lint <chart>

# 4. Verify values
helm get values <release> -n <namespace>
```

### Upgrade Failing

```bash
# 1. Check release history
helm history <release> -n <namespace>

# 2. See what changed
helm diff upgrade <release> <chart> -f newvalues.yaml

# 3. Rollback if needed
helm rollback <release> <revision> -n <namespace>

# 4. Check rendered manifests
helm get manifest <release> -n <namespace>
```

### Debug Failed Release

```bash
# Show all info about release
helm get all <release> -n <namespace>

# Check what's actually deployed
helm list -n <namespace> --all

# Delete stuck release
helm uninstall <release> -n <namespace>
```

---

## 7. Performance Issues

### High CPU Usage

```bash
# 1. Check top pods
kubectl top pods -n <namespace> --sort-by=cpu

# 2. Check resource limits
kubectl describe pod <pod> -n <namespace> | grep -A 5 "Limits"

# 3. Increase CPU limits if needed
resources:
  limits:
    cpu: "1000m"  # 1 CPU core
  requests:
    cpu: "500m"   # 0.5 CPU core
```

### High Memory Usage

```bash
# 1. Check top pods
kubectl top pods -n <namespace> --sort-by=memory

# 2. Check for memory leaks in logs
kubectl logs <pod> -n <namespace> | grep -i "memory\|oom"

# 3. Adjust memory limits
resources:
  limits:
    memory: "512Mi"
  requests:
    memory: "256Mi"
```

---

## 8. Common Commands Cheat Sheet

### Inspection

```bash
# Overview
kubectl get all -n <namespace>
kubectl get pods -A -o wide
kubectl cluster-info

# Details
kubectl describe <resource> <name> -n <namespace>
kubectl get <resource> <name> -o yaml
kubectl get <resource> <name> -o json | jq

# Logs
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -c <container> -n <namespace>
kubectl logs <pod> --previous -n <namespace>
kubectl logs -f <pod> -n <namespace>  # Follow
```

### Diagnostics

```bash
# Events
kubectl get events --sort-by='.lastTimestamp' -n <namespace>
kubectl get events --watch

# Resource usage
kubectl top nodes
kubectl top pods -n <namespace>
kubectl top pods --containers -n <namespace>

# Labels and selectors
kubectl get pods --show-labels
kubectl get pods -l app=myapp
```

### Editing and Updating

```bash
# Edit resource (avoid in production)
kubectl edit <resource> <name> -n <namespace>

# Update via Helm (preferred)
helm upgrade <release> <chart> -f values.yaml

# Patch resource
kubectl patch <resource> <name> -p '{"spec":{"replicas":3}}'

# Scale
kubectl scale deployment <name> --replicas=3
```

### Cleanup

```bash
# Delete resources
kubectl delete pod <name> -n <namespace>
kubectl delete -f manifest.yaml
helm uninstall <release> -n <namespace>

# Force delete stuck pod
kubectl delete pod <name> --grace-period=0 --force -n <namespace>

# Delete namespace (deletes everything in it)
kubectl delete namespace <namespace>
```

---

## 9. Best Practices

### Before Making Changes

1. **Always check current state first:**
   ```bash
   kubectl get pods -n <namespace>
   helm list -n <namespace>
   ```

2. **Dry-run when possible:**
   ```bash
   kubectl apply -f manifest.yaml --dry-run=client
   helm upgrade --dry-run --debug <release> <chart>
   ```

3. **Use namespaces for isolation:**
   ```bash
   kubectl create namespace test-env
   helm install app ./chart -n test-env
   ```

### During Troubleshooting

1. **Check the obvious first:**
   - Is the pod running?
   - Are there recent events?
   - What do the logs say?

2. **Document what you try:**
   - Keep notes of commands run
   - Record error messages
   - Note what worked vs. what didn't

3. **Start broad, then narrow:**
   - `kubectl get pods` (overview)
   - `kubectl describe pod` (details)
   - `kubectl logs` (specifics)

### After Resolving

1. **Verify the fix:**
   - Pod status is Running
   - Application is accessible
   - No error logs

2. **Clean up test resources:**
   ```bash
   kubectl delete namespace test-env
   ```

3. **Document the solution:**
   - What was the problem?
   - What was the root cause?
   - How was it fixed?
   - How to prevent in future?

---

## 10. Emergency Procedures

### Cluster Not Responding

```bash
# 1. Check node status
kubectl get nodes

# 2. Check system pods
kubectl get pods -n kube-system

# 3. Check kubelet on nodes (SSH to node)
systemctl status kubelet
journalctl -u kubelet -f

# 4. Restart kubelet if needed
systemctl restart kubelet
```

### Pod Stuck in Terminating

```bash
# 1. Try normal delete
kubectl delete pod <pod> -n <namespace>

# 2. Force delete
kubectl delete pod <pod> -n <namespace> --grace-period=0 --force

# 3. If still stuck, remove finalizers
kubectl patch pod <pod> -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### Rollback Deployment

```bash
# Via kubectl
kubectl rollout undo deployment/<name> -n <namespace>

# Via Helm
helm rollback <release> <revision> -n <namespace>

# Check rollout status
kubectl rollout status deployment/<name> -n <namespace>
```

---

## Appendix: Exit Code Reference

| Exit Code | Signal | Meaning |
|-----------|--------|---------|
| 0 | - | Success (but check if pod should exit) |
| 1 | - | Application error |
| 2 | - | Misuse of shell command |
| 126 | - | Command cannot execute |
| 127 | - | Command not found |
| 128+n | n | Fatal error signal "n" |
| 130 | 2 | SIGINT (Ctrl+C) |
| 137 | 9 | SIGKILL (OOMKilled if in K8s) |
| 143 | 15 | SIGTERM (Graceful termination) |

---

**Remember:** Troubleshooting is a skill that improves with practice. Don't be afraid to experiment in your lab environment!
