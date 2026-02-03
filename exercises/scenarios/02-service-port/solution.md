# Solution: The Unreachable Service

## Quick Answer

The Service is configured to forward traffic to port `9090` on the pods, but the application container is actually listening on port `8080`. This port mismatch causes all traffic to fail.

**Fix:** Change `targetPort` from 9090 to 8080 in values.yaml

---

## Detailed Step-by-Step Solution

### Step 1: Verify Pods Are Running

```bash
kubectl get pods -n exercise-02
```

**Expected Output:**
```
NAME                      READY   STATUS    RESTARTS   AGE
webapp-5c7d8f9b6a-abc12   1/1     Running   0          2m
```

**Analysis:** Pod is healthy, so the issue isn't with the application itself.

### Step 2: Test Direct Pod Access

First, get the pod name:
```bash
POD_NAME=$(kubectl get pods -n exercise-02 -l app.kubernetes.io/name=broken-service -o jsonpath='{.items[0].metadata.name}')
```

Test the application directly on port 8080:
```bash
kubectl exec -it $POD_NAME -n exercise-02 -- wget -O- http://localhost:8080
```

**Expected Output:**
```
Connecting to localhost:8080 (127.0.0.1:8080)
Hello from pod: webapp-5c7d8f9b6a-abc12!
```

**Conclusion:** The application IS working and IS listening on port 8080!

### Step 3: Check Service Configuration

```bash
kubectl describe svc webapp-service -n exercise-02
```

**Expected Output:**
```
Name:              webapp-service
Namespace:         exercise-02
Labels:            app.kubernetes.io/name=broken-service
Selector:          app.kubernetes.io/name=broken-service,app.kubernetes.io/instance=webapp
Type:              ClusterIP
IP:                10.96.123.45
Port:              http  80/TCP
TargetPort:        9090/TCP          ❌ PROBLEM IS HERE!
Endpoints:         10.244.1.5:9090   ❌ Pointing to wrong port!
```

**Critical Discovery:**
- Service Port: 80 (external facing) ✅
- Target Port: 9090 (where service sends traffic) ❌ WRONG!
- Container Port: 8080 (where app listens) ✅
- **Mismatch:** Service sends to 9090, but app listens on 8080!

### Step 4: Verify the Issue with Endpoints

```bash
kubectl get endpoints webapp-service -n exercise-02
```

**Output:**
```
NAME             ENDPOINTS         AGE
webapp-service   10.244.1.5:9090   5m
```

The endpoint exists but targets port 9090. Let's test if anything is listening there:

```bash
kubectl exec -it $POD_NAME -n exercise-02 -- wget -O- http://localhost:9090 --timeout=2
```

**Expected Output:**
```
Connecting to localhost:9090 (127.0.0.1:9090)
wget: can't connect to remote host (127.0.0.1): Connection refused
```

**Confirmed:** Nothing is listening on port 9090!

### Step 5: Test Service Connectivity (Should Fail)

Deploy a debug pod to test service access:

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -n exercise-02 -- /bin/bash
```

Inside the debug pod:
```bash
# Test DNS resolution
nslookup webapp-service

# Try to connect to service
curl http://webapp-service:80 --max-time 5
```

**Expected Output:**
```
# DNS works:
Server:    10.96.0.10
Address:   10.96.0.10#53

Name:   webapp-service.exercise-02.svc.cluster.local
Address: 10.96.123.45

# But connection fails:
curl: (28) Connection timed out after 5001 milliseconds
```

**Analysis:**
- ✅ DNS resolution works (service exists)
- ❌ Connection fails (wrong target port)

### Step 6: Check Current Helm Values

```bash
helm get values webapp -n exercise-02
```

**Output:**
```yaml
service:
  port: 80
  targetPort: 9090    # ❌ This is wrong!
  type: ClusterIP
```

### Step 7: Create Fixed Values

Create `fixed-values.yaml`:

```yaml
# fixed-values.yaml
service:
  port: 80
  targetPort: 8080    # ✅ Changed from 9090 to 8080
  type: ClusterIP
```

### Step 8: Apply the Fix

```bash
helm upgrade webapp helm-charts/broken-service \
  -n exercise-02 \
  -f fixed-values.yaml
```

**Expected Output:**
```
Release "webapp" has been upgraded. Happy Helming!
NAME: webapp
NAMESPACE: exercise-02
STATUS: deployed
REVISION: 2
```

### Step 9: Verify the Fix

Check the updated service:
```bash
kubectl describe svc webapp-service -n exercise-02
```

**Corrected Output:**
```
Name:              webapp-service
Port:              http  80/TCP
TargetPort:        8080/TCP          ✅ NOW CORRECT!
Endpoints:         10.244.1.5:8080   ✅ Pointing to right port!
```

Check endpoints:
```bash
kubectl get endpoints webapp-service -n exercise-02
```

**Output:**
```
NAME             ENDPOINTS         AGE
webapp-service   10.244.1.5:8080   7m
```

### Step 10: Test Connectivity

```bash
kubectl run curl-test --image=curlimages/curl:latest --rm -it --restart=Never \
  -n exercise-02 -- curl http://webapp-service:80
```

**Success Output:**
```
Hello from pod: webapp-5c7d8f9b6a-abc12!
pod "curl-test" deleted
```

**Alternatively, use a debug pod:**
```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -n exercise-02 -- curl http://webapp-service:80
```

---

## Root Cause Analysis

### The Port Configuration Hierarchy

Kubernetes uses three related but distinct port configurations:

```
Client → Service.port → Service.targetPort → Container.containerPort
```

1. **Service Port** (80): External-facing port that clients connect to
2. **Target Port** (9090 ❌ → 8080 ✅): Port on the pod where traffic is sent
3. **Container Port** (8080): Port the application listens on inside the container

### What Went Wrong

```yaml
# Deployment (Correct)
containers:
- name: webapp
  ports:
  - containerPort: 8080    # ✅ App listens here

# Service (Incorrect)
ports:
- port: 80                 # ✅ External port
  targetPort: 9090         # ❌ Wrong! Nothing listening here
```

**Result:**
```
Client request → Service:80 → Forward to Pod:9090 → Nothing listening → Timeout
```

**Should be:**
```
Client request → Service:80 → Forward to Pod:8080 → App responds → Success
```

### Why Did This Happen?

Common causes of this mistake:
1. **Copy-paste error** - Copied service config from another project
2. **Template reuse** - Didn't update all values when creating chart
3. **Miscommunication** - Developer changed container port but didn't tell ops
4. **Lack of testing** - Never tested service connectivity before deploying

---

## Understanding Kubernetes Service Ports

### Port Configuration Explained

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - name: http
    port: 80          # Service listens on this port
    targetPort: 8080  # Forwards to this port on pods
    protocol: TCP
```

**Detailed breakdown:**

| Field | Purpose | Example | Who Uses It |
|-------|---------|---------|-------------|
| `port` | Service's listening port | `80` | Clients connecting to service |
| `targetPort` | Pod's receiving port | `8080` | Service → Pod forwarding |
| `containerPort` | Container's listening port | `8080` | Application inside container |

### Port Matching Rules

✅ **MUST match:** `targetPort` = `containerPort`  
✅ **CAN differ:** `port` ≠ `targetPort`

**Example valid configurations:**

```yaml
# Configuration 1: All same
Service port: 8080 → targetPort: 8080 → containerPort: 8080

# Configuration 2: Service port differs
Service port: 80 → targetPort: 8080 → containerPort: 8080

# Configuration 3: Using port names
Service targetPort: "http" → containerPort name: "http" (8080)
```

### Using Named Ports (Best Practice)

Instead of numbers, use names for better clarity:

```yaml
# Deployment
containers:
- name: webapp
  ports:
  - name: http        # Named port
    containerPort: 8080

# Service
ports:
- port: 80
  targetPort: http    # References the name
```

**Benefits:**
- Less error-prone
- Self-documenting
- Easier to change ports (update one place)

---

## Diagnostic Commands Explained

### 1. Direct Pod Testing

```bash
# Test app inside the pod
kubectl exec -it <pod> -- wget -O- http://localhost:8080

# Why: Verifies the application itself works
# If this fails: Problem is with the app
# If this succeeds: Problem is with service/networking
```

### 2. Service Description

```bash
kubectl describe svc <service-name>

# Look for:
# - TargetPort: Should match containerPort
# - Endpoints: Should have pod IPs listed
# - Selector: Should match pod labels
```

### 3. Endpoints Verification

```bash
kubectl get endpoints <service-name>

# Shows: Which pod IPs and ports the service targets
# Empty endpoints = selector mismatch or no ready pods
# Wrong port = targetPort misconfiguration
```

### 4. Network Debugging Pod

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- /bin/bash

# Inside pod:
nslookup <service-name>              # DNS resolution
curl http://<service-name>:<port>    # HTTP connectivity
ping <pod-ip>                        # Pod reachability
```

### 5. Port Forwarding (Alternative Test)

```bash
# Forward service port to localhost
kubectl port-forward svc/<service-name> 8080:80

# Then test from your machine:
curl http://localhost:8080
```

---

## Prevention Strategies

### 1. Use Port Name References

```yaml
# values.yaml
containerPort: 8080

# deployment.yaml
ports:
- name: http
  containerPort: {{ .Values.containerPort }}

# service.yaml
ports:
- port: 80
  targetPort: http    # Uses name, not number
```

### 2. Validate Helm Templates

```bash
# Render templates and check ports
helm template . | grep -A 5 "kind: Service"
helm template . | grep -A 5 "containerPort"

# Ensure targetPort matches containerPort
```

### 3. Automated Testing

Create a test script:
```bash
#!/bin/bash
# test-service.sh

POD=$(kubectl get pods -l app=myapp -o name | head -1)

# Test direct pod access
echo "Testing pod directly..."
kubectl exec $POD -- wget -qO- http://localhost:8080 || exit 1

# Test service access
echo "Testing service..."
kubectl run test --rm -i --image=curlimages/curl -- \
  curl -sf http://myservice:80 || exit 1

echo "✅ All tests passed!"
```

### 4. Readiness Probes

Add probes to catch port issues early:

```yaml
readinessProbe:
  httpGet:
    port: 8080    # Must match containerPort
    path: /health
  initialDelaySeconds: 5
  periodSeconds: 10
```

If probe fails → Pod not ready → Not added to service endpoints

---

## Service Types Overview

### ClusterIP (Default)

```yaml
type: ClusterIP
```

- ✅ Internal cluster access only
- ❌ Not accessible from outside
- **Use for:** Internal microservices

### NodePort

```yaml
type: NodePort
ports:
- port: 80
  targetPort: 8080
  nodePort: 30080    # Optional: K8s assigns if omitted
```

- ✅ Accessible via `<NodeIP>:30080`
- ⚠️ Opens port on all nodes
- **Use for:** Development, testing

### LoadBalancer

```yaml
type: LoadBalancer
```

- ✅ External IP assigned by cloud provider
- ⚠️ Costs money (cloud load balancer)
- **Use for:** Production external services

### ExternalName

```yaml
type: ExternalName
externalName: external-service.example.com
```

- Maps service to external DNS
- **Use for:** Integrating external services

---

## Additional Debugging Tips

### Check Service Selector Matches Pods

```bash
# Service selector
kubectl get svc webapp-service -o jsonpath='{.spec.selector}'

# Pod labels
kubectl get pods --show-labels

# They must match!
```

### Use kubect get all for Overview

```bash
kubectl get all -n exercise-02

# Shows: pods, services, deployments, replicasets
# Quick way to see if everything is deployed
```

### Test with Different Tools

```bash
# wget (simpler, good for quick tests)
kubectl run wget-test --rm -it --image=busybox -- wget -O- http://service:80

# curl (more features, better error messages)
kubectl run curl-test --rm -it --image=curlimages/curl -- curl -v http://service:80

# netshoot (full networking toolkit)
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash
```

---

## Congratulations! 🎉

You've successfully:
- ✅ Diagnosed a service port misconfiguration
- ✅ Differentiated between service, target, and container ports
- ✅ Used debug pods for network troubleshooting
- ✅ Verified service endpoints
- ✅ Fixed the issue via Helm upgrade

**Ready for more?** Move on to [Scenario 3: Image Pull Nightmare](../03-image-pull/README.md)
