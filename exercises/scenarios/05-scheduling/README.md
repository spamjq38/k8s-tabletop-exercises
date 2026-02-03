# Scenario 5: Scheduling Standstill

**Difficulty:** ⭐⭐⭐ Advanced  
**Estimated Time:** 30-35 minutes  
**Skills Practiced:** 
- Pod scheduling troubleshooting
- Node selectors and affinity
- Taints and tolerations
- Resource constraints
- Scheduler debugging

## Problem Statement

Several critical applications are stuck in `Pending` state and won't schedule on any nodes. The cluster has resources available, but the Kubernetes scheduler can't place the pods. This is causing outages and blocking deployments.

Your task is to:
1. Identify why pods aren't scheduling
2. Understand node taints, selectors, and affinity rules
3. Fix each scheduling issue
4. Verify all pods are running on appropriate nodes

## Background

This scenario includes five common scheduling problems:
- **Node selector mismatch** - Label doesn't exist on any node
- **Taint without toleration** - Node is tainted but pod doesn't tolerate it
- **Insufficient resources** - Pod requests more than available
- **Anti-affinity conflict** - Pod can't be co-located with existing pods
- **Node selector AND resource issue** - Multiple problems combined

## Success Criteria

✅ All pods move from `Pending` to `Running` state  
✅ Pods are scheduled on appropriate nodes  
✅ No resource constraint violations  
✅ Taint/toleration pairs are correct

## Setup

1. **Create a dedicated namespace:**
   ```bash
   kubectl create namespace exercise-05
   kubens exercise-05
   ```

2. **Label and taint nodes for the exercise:**
   ```bash
   cd /root/tabletop-exercises/scenarios/05-scheduling
   bash setup-nodes.sh
   ```

3. **Deploy the problematic pods:**
   ```bash
   kubectl apply -f broken-scheduling.yaml
   ```

4. **Check the pending pods:**
   ```bash
   kubectl get pods -n exercise-05
   ```

## Your Mission

### Phase 1: Observation (10 minutes)
- Identify pending pods
- Check node labels and taints
- Review pod scheduling requirements

### Phase 2: Diagnosis (10 minutes)
- Examine scheduler events
- Check resource availability
- Analyze affinity/anti-affinity rules

### Phase 3: Resolution (10 minutes)
- Fix node selectors
- Add tolerations where needed
- Adjust resource requests
- Modify affinity rules

## Hints

<details>
<summary>Hint 1: Finding why pods are pending</summary>

```bash
kubectl describe pod <pod-name> -n exercise-05 | grep -A 10 Events
# Look for: "FailedScheduling" events
```

</details>

<details>
<summary>Hint 2: Checking node labels and taints</summary>

```bash
# View all node labels
kubectl get nodes --show-labels

# View node taints
kubectl describe node <node-name> | grep Taints

# View all nodes with details
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

</details>

<details>
<summary>Hint 3: Common scheduling failures</summary>

- `0/2 nodes are available: 2 node(s) didn't match Pod's node affinity/selector`
- `0/2 nodes are available: 2 node(s) had taint that the pod didn't tolerate`
- `0/2 nodes are available: 2 Insufficient cpu`
- `0/2 nodes are available: 2 node(s) didn't match pod anti-affinity rules`

</details>

<details>
<summary>Hint 4: How to fix node selector issues</summary>

Either add the label to a node OR change the pod's nodeSelector:

```bash
# Add label to node
kubectl label node <node-name> environment=production

# Or edit deployment to use existing label
kubectl edit deployment <name> -n exercise-05
```

</details>

<details>
<summary>Hint 5: How to add tolerations</summary>

```yaml
spec:
  tolerations:
  - key: "special"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
```

</details>

## Common Commands

```bash
# Check pod scheduling status
kubectl get pods -n exercise-05 -o wide

# Describe pod to see scheduling events
kubectl describe pod <pod-name> -n exercise-05

# View node information
kubectl get nodes
kubectl describe node <node-name>

# Check node labels
kubectl get nodes --show-labels

# Add node label
kubectl label node <node-name> key=value

# Remove node label
kubectl label node <node-name> key-

# View node taints
kubectl describe nodes | grep -i taint

# Add taint to node
kubectl taint node <node-name> key=value:NoSchedule

# Remove taint
kubectl taint node <node-name> key:NoSchedule-

# Check resource usage
kubectl top nodes
kubectl describe node <name> | grep -A 10 "Allocated resources"

# Force reschedule
kubectl delete pod <pod-name> -n exercise-05
```

## Learning Objectives

After completing this scenario, you will understand:

1. **Node selectors** - How to constrain pods to specific nodes
2. **Taints and tolerations** - Preventing pods from scheduling on certain nodes
3. **Resource requests/limits** - How scheduler uses them
4. **Pod affinity/anti-affinity** - Co-location and separation rules
5. **Scheduler decision process** - Why pods get placed where they do

## Cleanup

```bash
# Remove node labels and taints
bash cleanup-nodes.sh

# Delete namespace
kubectl delete namespace exercise-05
```

## Real-World Applications

Scheduling issues occur frequently:
- **GPU nodes** - Only schedule ML workloads with GPUs
- **High-memory nodes** - Database pods on appropriate hardware
- **Dedicated nodes** - Keep production separate from dev
- **Compliance** - Ensure sensitive workloads run in specific zones
- **Cost optimization** - Use spot instances with tolerations

## Advanced Topics

- **Pod Priority and Preemption**
- **Custom Schedulers**
- **Topology Spread Constraints**
- **Cluster Autoscaler behavior**

## Next Steps

- Review Kubernetes scheduler documentation
- Experiment with custom schedulers
- Learn about Karpenter for advanced scheduling
- Explore Descheduler for rebalancing
