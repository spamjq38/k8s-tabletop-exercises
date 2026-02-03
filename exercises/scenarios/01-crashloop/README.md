# Scenario 1: Memory Limit Mayhem

**Difficulty:** ⭐ Beginner  
**Estimated Time:** 15-20 minutes  
**Skills Practiced:** 
- Pod diagnostics
- Resource limits understanding
- Log analysis
- Helm value modification

## Problem Statement

Your development team has deployed a new data processing application to production. The application works perfectly in the development environment, but in production it keeps crashing and restarting. The monitoring team reports that pods are in `CrashLoopBackOff` state.

Your task is to:
1. Identify why the pods are crashing
2. Determine the root cause
3. Fix the issue using Helm
4. Verify the application runs stably

## Background

The application is a simple memory-intensive data processor that:
- Loads data into memory for fast processing
- Requires approximately 128Mi of RAM to function
- Was deployed with production-hardened resource limits

Someone on the ops team set very conservative memory limits to "save resources" without testing the actual requirements.

## Success Criteria

✅ Pod is in `Running` state and stays running  
✅ Pod does not restart (restart count = 0)  
✅ Application logs show successful operation  
✅ Fix is applied via Helm (not manual kubectl edits)

## Setup

**Prerequisites:** Ensure exercises are deployed to the cluster (run `bash deploy_exercises.sh` from your local machine first).

1. **SSH to control plane** (if not already connected):
   ```bash
   ssh root@192.168.122.100
   cd /root/tabletop-exercises
   ```

2. **Create a dedicated namespace:**
   ```bash
   kubectl create namespace exercise-01
   kubens exercise-01
   ```

3. **Deploy the broken application:**
   ```bash
   helm install memory-app helm-charts/memory-hog -n exercise-01
   ```

4. **Wait 30 seconds for the issue to manifest:**
   ```bash
   sleep 30
   kubectl get pods -n exercise-01
   ```

## Your Mission

Use the troubleshooting workflow to diagnose and fix the issue:

### Phase 1: Observation (5 minutes)
- Check pod status
- Look at events
- Review pod description

### Phase 2: Diagnosis (5 minutes)
- Examine container logs
- Identify the specific error
- Determine root cause

### Phase 3: Resolution (5 minutes)
- Create a fixed values.yaml file
- Upgrade the Helm release
- Verify the fix

## Hints

<details>
<summary>Hint 1: Where to start?</summary>

Always start with `kubectl get pods` to see the current state. Look for the STATUS column - what does `CrashLoopBackOff` tell you?

</details>

<details>
<summary>Hint 2: What command gives detailed information?</summary>

Use `kubectl describe pod <pod-name>` to see events and container status. Pay attention to the "Last State" section.

</details>

<details>
<summary>Hint 3: What are the exact error messages?</summary>

Check logs with `kubectl logs <pod-name>`. You might also need `kubectl logs <pod-name> --previous` to see logs from the crashed container.

</details>

<details>
<summary>Hint 4: What needs to be changed?</summary>

Look at the resource limits in the Helm chart's values.yaml. Compare them to what the application actually needs (check the logs for memory usage).

</details>

## Solution

Only look at this after attempting the exercise yourself!

[Solution Guide](solution.md)

## Cleanup

When you're done with this scenario:

```bash
helm uninstall memory-app -n exercise-01
kubectl delete namespace exercise-01
```

## What You Learned

After completing this scenario, you should understand:

- ✅ How to identify `CrashLoopBackOff` issues
- ✅ The difference between resource `requests` and `limits`
- ✅ How insufficient memory causes OOMKilled errors
- ✅ How to use `kubectl describe` and `kubectl logs` effectively
- ✅ How to fix issues by modifying Helm values
- ✅ The importance of proper resource allocation

## Next Steps

Continue to **[Scenario 2: The Unreachable Service](../02-service-port/README.md)** to practice network troubleshooting.

## Additional Challenges

Want more practice?

1. **Modify the scenario:**
   - Set CPU limits too low instead of memory
   - Create both memory AND CPU constraints
   - Set requests higher than node capacity

2. **Add monitoring:**
   - Use `kubectl top pods` to see actual resource usage
   - Compare actual vs. requested vs. limit

3. **Production simulation:**
   - Add readiness and liveness probes
   - See how they interact with resource limits
