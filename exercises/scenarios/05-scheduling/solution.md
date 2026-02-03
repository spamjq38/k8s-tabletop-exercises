# Scheduling Standstill - Solutions

## Overview
This guide provides step-by-step solutions for all five scheduling problems.

---

## Problem 1: Node Selector - Label Doesn't Exist

**Symptom:**
```bash
kubectl get pods -n exercise-05 | grep wrong-selector
# wrong-selector-app-xxxxx   0/1     Pending
```

**Diagnosis:**
```bash
kubectl describe pod -n exercise-05 -l app=wrong-selector
```
Look for: `Warning  FailedScheduling ... 0/2 nodes are available: 2 node(s) didn't match Pod's node affinity/selector.`

**Root Cause:**
Pod requests `environment=production` but no node has this label.

**Verify Node Labels:**
```bash
kubectl get nodes --show-labels | grep environment
```

**Solution Option 1 - Fix the Label (Recommended):**
```bash
# Change selector to match actual label
kubectl patch deployment wrong-selector-app -n exercise-05 --type json -p='[
  {"op": "replace", "path": "/spec/template/spec/nodeSelector/environment", "value": "staging"}
]'
```

**Solution Option 2 - Add Label to Node:**
```bash
WORKER=$(kubectl get nodes -o jsonpath='{.items[?(!@.metadata.labels.node-role\.kubernetes\.io/control-plane)].metadata.name}')
kubectl label node $WORKER environment=production --overwrite
```

**Verify Fix:**
```bash
kubectl get pods -n exercise-05 -l app=wrong-selector -w
# Should transition to Running
```

---

## Problem 2: Taint Without Toleration

**Symptom:**
```bash
kubectl get pods -n exercise-05 | grep no-toleration
# no-toleration-app-xxxxx   0/1     Pending
```

**Diagnosis:**
```bash
kubectl describe pod -n exercise-05 -l app=no-toleration
```
Look for: `Warning  FailedScheduling ... 0/2 nodes are available: 1 node(s) had untolerated taint {special: true}`

**Check Node Taints:**
```bash
kubectl describe nodes | grep -E "^Name:|Taints:"
```

**Root Cause:**
Pod tries to schedule on control plane which has `special=true:NoSchedule` taint, but pod has no matching toleration.

**Solution - Add Toleration:**
```bash
kubectl patch deployment no-toleration-app -n exercise-05 --type json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/tolerations",
    "value": [
      {
        "key": "special",
        "operator": "Equal",
        "value": "true",
        "effect": "NoSchedule"
      }
    ]
  }
]'
```

**Alternative - Remove Node Selector:**
```bash
# Let it schedule on worker node instead
kubectl patch deployment no-toleration-app -n exercise-05 --type json -p='[
  {"op": "remove", "path": "/spec/template/spec/nodeSelector"}
]'
```

**Verify Fix:**
```bash
kubectl get pods -n exercise-05 -l app=no-toleration -w
```

---

## Problem 3: Excessive Resource Requests

**Symptom:**
```bash
kubectl get pods -n exercise-05 | grep resource-hog
# resource-hog-app-xxxxx   0/1     Pending
```

**Diagnosis:**
```bash
kubectl describe pod -n exercise-05 -l app=resource-hog
```
Look for: `Warning  FailedScheduling ... 0/2 nodes are available: 2 Insufficient cpu, 2 Insufficient memory.`

**Check Node Capacity:**
```bash
kubectl describe nodes | grep -A 5 "Allocatable:"
```

**Root Cause:**
Pod requests 32GB RAM and 16 CPUs, but cluster nodes only have ~3GB RAM and 2-3 CPUs each.

**Solution - Reduce Resource Requests:**
```bash
kubectl patch deployment resource-hog-app -n exercise-05 --type json -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "128Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "100m"}
]'
```

**Verify Fix:**
```bash
kubectl get pods -n exercise-05 -l app=resource-hog -w
```

---

## Problem 4: Pod Anti-Affinity Conflict

**Symptom:**
```bash
kubectl get pods -n exercise-05 | grep anti-affinity
# anti-affinity-app-xxxxx   0/1     Pending   (one of two replicas)
```

**Diagnosis:**
```bash
kubectl describe pod -n exercise-05 -l app=anti-affinity | grep -A 3 "Events:"
```
Look for: `Warning  FailedScheduling ... didn't match pod anti-affinity rules`

**Check Existing Backend Pods:**
```bash
kubectl get pods -n exercise-05 -l tier=backend -o wide
# Shows database-pod on one node, anti-affinity pod on another
```

**Root Cause:**
- Anti-affinity rule requires all `tier=backend` pods be on different nodes
- Already have `database-pod` on one node and 1 `anti-affinity-app` replica on the other
- Only 2 nodes total, can't place second `anti-affinity-app` replica

**Solution Option 1 - Reduce Replicas:**
```bash
kubectl scale deployment anti-affinity-app -n exercise-05 --replicas=1
```

**Solution Option 2 - Change to Preferred Anti-Affinity:**
```bash
kubectl delete deployment anti-affinity-app -n exercise-05
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: anti-affinity-app
  namespace: exercise-05
spec:
  replicas: 2
  selector:
    matchLabels:
      app: anti-affinity
      tier: backend
  template:
    metadata:
      labels:
        app: anti-affinity
        tier: backend
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:  # Changed from required
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: tier
                  operator: In
                  values:
                  - backend
              topologyKey: kubernetes.io/hostname
      containers:
      - name: app
        image: nginx:latest
        resources:
          requests:
            memory: "32Mi"
            cpu: "50m"
EOF
```

**Solution Option 3 - Remove database-pod:**
```bash
# If database pod isn't needed for this exercise
kubectl delete pod database-pod -n exercise-05
```

**Verify Fix:**
```bash
kubectl get pods -n exercise-05 -l app=anti-affinity -o wide
# Should show both replicas running
```

---

## Problem 5: Multiple Issues Combined

**Symptom:**
```bash
kubectl get pods -n exercise-05 | grep multi-problem
# multi-problem-app-xxxxx   0/1     Pending
```

**Diagnosis:**
```bash
kubectl describe pod -n exercise-05 -l app=multi-problem
```
Look for multiple issues:
- `node(s) didn't match Pod's node affinity/selector` (disktype=nvme doesn't exist)
- `Insufficient cpu, Insufficient memory` (8GB RAM, 4 CPUs too much)

**Solution - Fix Both Issues:**
```bash
# Fix node selector
kubectl patch deployment multi-problem-app -n exercise-05 --type json -p='[
  {"op": "replace", "path": "/spec/template/spec/nodeSelector/disktype", "value": "ssd"}
]'

# Fix resource requests
kubectl patch deployment multi-problem-app -n exercise-05 --type json -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "128Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "100m"}
]'
```

**Verify Fix:**
```bash
kubectl get pods -n exercise-05 -l app=multi-problem -w
```

---

## Cleanup

After completing all exercises:

```bash
# Delete all resources
kubectl delete namespace exercise-05

# Remove node labels and taints
bash cleanup-nodes.sh
```

---

## Key Takeaways

### Node Selectors
- Ensure labels exist on nodes before using nodeSelector
- Check with: `kubectl get nodes --show-labels`
- Add labels with: `kubectl label node <node-name> key=value`

### Taints and Tolerations
- Taints prevent pods from scheduling unless they have matching tolerations
- Check taints with: `kubectl describe nodes | grep Taints`
- Tolerations must match taint key, value, and effect exactly

### Resource Requests
- Pods won't schedule if they request more than node capacity
- Check node capacity: `kubectl describe nodes | grep -A 5 Allocatable`
- Be realistic with resource requests - use actual application needs

### Pod Affinity/Anti-Affinity
- `requiredDuringScheduling` is strict - pod won't schedule if rule can't be met
- `preferredDuringScheduling` is soft - scheduler tries but will schedule anyway
- Consider cluster size when using anti-affinity rules
- `topologyKey: kubernetes.io/hostname` spreads across nodes

### Troubleshooting Process
1. Check pod events: `kubectl describe pod <pod-name>`
2. Look for "FailedScheduling" warnings
3. Verify node labels, taints, and capacity
4. Compare pod requirements with node capabilities
5. Adjust pod spec or node configuration as needed

### Production Best Practices
- Use labels consistently across your cluster
- Document taint purposes and required tolerations
- Set realistic resource requests based on monitoring
- Use preferred anti-affinity for flexibility
- Monitor scheduling metrics with Prometheus
