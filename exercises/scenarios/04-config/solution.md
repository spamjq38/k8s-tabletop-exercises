# Solution: Configuration Chaos

## Step-by-Step Solution

### Step 1: Identify the Problems

```bash
kubectl get pods -n exercise-04

# You should see various states:
# missing-configmap-pod     0/1     CreateContainerConfigError
# wrong-key-pod             0/1     CreateContainerConfigError  
# missing-secret-pod        0/1     CreateContainerConfigError
# env-typo-pod              0/1     CrashLoopBackOff
```

### Step 2: Diagnose Each Issue

**Problem 1: Missing ConfigMap**
```bash
kubectl describe pod missing-configmap-pod -n exercise-04
# Error: configmap "app-config" not found
```

**Problem 2: Wrong ConfigMap Key**
```bash
kubectl describe pod wrong-key-pod -n exercise-04
# Error: key "database_user" not found in ConfigMap "database-config"

# Check what keys actually exist
kubectl get configmap database-config -n exercise-04 -o yaml
# Shows: db_user (not database_user)
```

**Problem 3: Missing Secret**
```bash
kubectl describe pod missing-secret-pod -n exercise-04
# Error: secret "db-credentials" not found
```

**Problem 4: Environment Variable Typo**
```bash
kubectl logs env-typo-pod -n exercise-04
# ERROR: API_URL environment variable not set!

# Check pod environment
kubectl get pod env-typo-pod -n exercise-04 -o yaml | grep -A 10 env:
# Shows: API_ENDPOINT is set, but app expects API_URL
```

### Step 3: Fix Each Issue

**Fix #1: Create the missing ConfigMap**
```bash
kubectl create configmap app-config \
  --from-literal=app.conf="# Application Config
server_port=8080
debug_mode=false
timeout=30" \
  -n exercise-04

# Delete and recreate pod to pick up the ConfigMap
kubectl delete pod missing-configmap-pod -n exercise-04
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: missing-configmap-pod
  namespace: exercise-04
spec:
  containers:
  - name: app
    image: busybox:latest
    command: ['sh', '-c', 'echo "Starting..."; cat /etc/config/app.conf; sleep 3600']
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-config
EOF
```

**Fix #2: Correct the ConfigMap key reference**
```bash
kubectl delete pod wrong-key-pod -n exercise-04
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: wrong-key-pod
  namespace: exercise-04
spec:
  containers:
  - name: app
    image: busybox:latest
    command: ['sh', '-c', 'echo "DB_USER is: \$DB_USER"; sleep 3600']
    env:
    - name: DB_USER
      valueFrom:
        configMapKeyRef:
          name: database-config
          key: db_user  # ✅ Fixed: changed from database_user to db_user
EOF
```

**Fix #3: Create the missing Secret**
```bash
kubectl create secret generic db-credentials \
  --from-literal=password=supersecret123 \
  -n exercise-04

# Delete and recreate pod
kubectl delete pod missing-secret-pod -n exercise-04
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: missing-secret-pod
  namespace: exercise-04
spec:
  containers:
  - name: app
    image: busybox:latest
    command: ['sh', '-c', 'echo "Password: \$DB_PASSWORD"; sleep 3600']
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
EOF
```

**Fix #4: Fix the environment variable name**
```bash
kubectl delete pod env-typo-pod -n exercise-04
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: env-typo-pod
  namespace: exercise-04
spec:
  containers:
  - name: app
    image: busybox:latest
    command: 
    - sh
    - -c
    - |
      if [ -z "\$API_URL" ]; then
        echo "ERROR: API_URL environment variable not set!"
        exit 1
      fi
      echo "API_URL is: \$API_URL"
      sleep 3600
    env:
    - name: API_URL  # ✅ Fixed: changed from API_ENDPOINT to API_URL
      valueFrom:
        configMapKeyRef:
          name: api-config
          key: api_endpoint
EOF
```

### Step 4: Verify All Fixes

```bash
# All pods should be running
kubectl get pods -n exercise-04

# Check logs to verify configuration loaded
kubectl logs missing-configmap-pod -n exercise-04
kubectl logs wrong-key-pod -n exercise-04
kubectl logs missing-secret-pod -n exercise-04
kubectl logs env-typo-pod -n exercise-04
```

## What We Learned

### ConfigMap Best Practices

1. **Create ConfigMaps before deploying pods**
   ```bash
   # Good order:
   kubectl apply -f configmaps.yaml
   kubectl apply -f deployments.yaml
   ```

2. **Use consistent key naming**
   ```yaml
   # Pick a convention and stick to it
   data:
     database_host: "..."  # snake_case
   # OR
     databaseHost: "..."   # camelCase
   ```

3. **Document expected keys**
   ```yaml
   # Add comments in ConfigMap
   data:
     # Database connection string
     db_url: "postgres://..."
   ```

### Secret Management

1. **Never commit secrets to Git**
   ```bash
   # Create from external source
   kubectl create secret generic db-creds \
     --from-file=password=./password.txt
   ```

2. **Use proper RBAC for secrets**
   ```yaml
   # Limit who can view secrets
   kubectl create role secret-reader --verb=get --resource=secrets
   ```

3. **Consider external secret management**
   - Vault
   - AWS Secrets Manager
   - Azure Key Vault
   - External Secrets Operator

### Environment Variables

1. **Match names in code and manifests**
   ```yaml
   # If code expects API_URL, use:
   env:
   - name: API_URL  # Must match exactly
   ```

2. **Use descriptive names**
   ```yaml
   env:
   - name: DATABASE_CONNECTION_STRING  # Clear
   # Not:
   - name: DB  # Ambiguous
   ```

3. **Validate required variables in code**
   ```sh
   # Check for required vars
   : ${REQUIRED_VAR:?REQUIRED_VAR must be set}
   ```

## Advanced Patterns

### Multi-file ConfigMaps
```bash
# Create from directory
kubectl create configmap multi-config \
  --from-file=configs/ \
  -n exercise-04
```

### Immutable ConfigMaps (K8s 1.19+)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: immutable-config
immutable: true  # Prevents modification
data:
  key: value
```

### Using envFrom
```yaml
# Load all ConfigMap keys as env vars
envFrom:
- configMapRef:
    name: app-config
- secretRef:
    name: db-credentials
```

## Troubleshooting Commands

```bash
# View all ConfigMaps
kubectl get cm -n exercise-04

# Decode Secret
kubectl get secret db-credentials -n exercise-04 -o jsonpath='{.data.password}' | base64 -d

# Check actual environment in running pod
kubectl exec -it <pod> -n exercise-04 -- env | sort

# View mounted ConfigMap files
kubectl exec -it <pod> -n exercise-04 -- cat /etc/config/app.conf

# Watch for ConfigMap updates
kubectl get cm -n exercise-04 -w
```

## Cleanup

```bash
kubectl delete namespace exercise-04
```

## Real-World Checklist

When deploying applications:
- [ ] ConfigMaps created before Deployments
- [ ] All referenced keys exist
- [ ] Secrets created and properly referenced
- [ ] Environment variable names match application code
- [ ] Volume mount paths don't conflict
- [ ] ConfigMap/Secret updates handled (restart pods if needed)
