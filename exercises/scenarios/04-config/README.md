# Scenario 4: Configuration Chaos

**Difficulty:** ⭐⭐ Intermediate  
**Estimated Time:** 25-30 minutes  
**Skills Practiced:** 
- ConfigMap troubleshooting
- Environment variable debugging
- Secret management
- Volume mount issues

## Problem Statement

A microservices application has been deployed, but several services are crashing or misbehaving due to configuration problems. The application expects configuration from ConfigMaps, Secrets, and environment variables, but something is wrong with how they're set up.

Your task is to:
1. Identify what configuration is missing or incorrect
2. Fix ConfigMap and Secret issues
3. Resolve environment variable problems
4. Get all services running with proper configuration

## Background

This scenario includes four common configuration issues:
- **Missing ConfigMap** - Referenced but not created
- **Wrong ConfigMap key** - Mounting non-existent key
- **Environment variable typo** - Variable name mismatch
- **Secret not found** - Referenced secret doesn't exist

## Success Criteria

✅ All pods are in `Running` state  
✅ Application logs show successful configuration loading  
✅ No CrashLoopBackOff due to config issues  
✅ ConfigMaps and Secrets properly mounted

## Setup

1. **Create a dedicated namespace:**
   ```bash
   kubectl create namespace exercise-04
   kubens exercise-04
   ```

2. **Deploy the broken configuration:**
   ```bash
   cd /root/tabletop-exercises/scenarios/04-config
   kubectl apply -f broken-config.yaml
   ```

3. **Wait 30 seconds and check status:**
   ```bash
   sleep 30
   kubectl get pods -n exercise-04
   ```

## Your Mission

### Phase 1: Observation (7 minutes)
- Check which pods are failing
- Look at pod events
- Review pod descriptions

### Phase 2: Diagnosis (10 minutes)
- Examine container logs
- Identify missing ConfigMaps/Secrets
- Check environment variable references

### Phase 3: Resolution (8 minutes)
- Create missing ConfigMaps
- Fix key references
- Correct environment variables
- Create required Secrets

## Hints

<details>
<summary>Hint 1: Finding configuration errors</summary>

```bash
kubectl describe pod <pod-name> -n exercise-04 | grep -i configmap
kubectl describe pod <pod-name> -n exercise-04 | grep -i secret
kubectl describe pod <pod-name> -n exercise-04 | grep -A 10 Events
```

</details>

<details>
<summary>Hint 2: Common error messages</summary>

- `configmap "xxx" not found` = ConfigMap doesn't exist
- `key "xxx" not found in ConfigMap` = Wrong key name
- `secret "xxx" not found` = Secret missing
- Container exits = Check logs for missing env vars

</details>

<details>
<summary>Hint 3: How to create ConfigMaps</summary>

```bash
# From literal values
kubectl create configmap app-config \
  --from-literal=DATABASE_URL=postgres://localhost:5432 \
  --from-literal=LOG_LEVEL=info \
  -n exercise-04

# From file
kubectl create configmap app-config \
  --from-file=config.properties \
  -n exercise-04
```

</details>

<details>
<summary>Hint 4: How to create Secrets</summary>

```bash
kubectl create secret generic db-password \
  --from-literal=password=supersecret123 \
  -n exercise-04
```

</details>

<details>
<summary>Hint 5: Checking what's actually mounted</summary>

```bash
# Exec into pod and check
kubectl exec -it <pod-name> -n exercise-04 -- sh
ls /etc/config/
cat /etc/config/app.conf
env | grep DATABASE
```

</details>

## Common Commands

```bash
# List ConfigMaps
kubectl get configmaps -n exercise-04

# Describe ConfigMap
kubectl describe configmap <name> -n exercise-04

# View ConfigMap data
kubectl get configmap <name> -n exercise-04 -o yaml

# List Secrets
kubectl get secrets -n exercise-04

# Create ConfigMap from literals
kubectl create configmap <name> --from-literal=KEY=value -n exercise-04

# Create Secret
kubectl create secret generic <name> --from-literal=key=value -n exercise-04

# Edit ConfigMap
kubectl edit configmap <name> -n exercise-04

# View pod environment variables
kubectl exec <pod> -n exercise-04 -- env

# Check mounted volumes
kubectl describe pod <pod> -n exercise-04 | grep -A 10 Mounts
```

## Learning Objectives

After completing this scenario, you will understand:

1. **ConfigMaps vs Secrets** - When to use each
2. **Environment variables** - Different ways to inject config
3. **Volume mounts** - Mounting config as files
4. **Key references** - Correct syntax for accessing config data
5. **Config updates** - How changes propagate to pods

## Cleanup

```bash
kubectl delete namespace exercise-04
```

## Real-World Applications

Configuration issues like these are extremely common:
- **Staging vs Production** - Wrong config for environment
- **Database migrations** - Connection string changes
- **Feature flags** - Missing or incorrect values
- **API keys** - Secret rotation and updates

## Next Steps

- Try Scenario 5: Scheduling Standstill
- Learn about ConfigMap and Secret best practices
- Explore external secret management (Vault, AWS Secrets Manager)
