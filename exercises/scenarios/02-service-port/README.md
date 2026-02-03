# Scenario 2: The Unreachable Service

**Difficulty:** ⭐⭐ Intermediate  
**Estimated Time:** 20-25 minutes  
**Skills Practiced:**
- Service networking
- Port troubleshooting
- Network debugging with debug pods
- Service endpoint verification

## Problem Statement

Your team deployed a new web API to the cluster. The pods are running perfectly, but no one can access the service. The development team says "it works on my machine" (of course!), but when deployed to Kubernetes, all requests timeout.

Your task is to:
1. Verify the pods are actually running and healthy
2. Identify why the service is not routing traffic correctly
3. Debug the networking configuration
4. Fix the service definition using Helm

## Background

The application is a simple web server that:
- Listens on port 8080 inside the container
- Responds with "Hello from pod!" when accessed
- Has no authentication or special requirements

A junior engineer created the Helm chart and "just copy-pasted from another project" for the Service configuration. They changed the image and deployment settings but forgot to update the service port mapping.

## Success Criteria

✅ Service successfully routes traffic to pods  
✅ Can curl the service and get a valid response  
✅ Service endpoint shows correct pod IPs  
✅ Fix is applied via Helm upgrade  

## Setup

1. **Create a dedicated namespace:**
   ```bash
   kubectl create namespace exercise-02
   kubens exercise-02
   ```

2. **Deploy the application:**
   ```bash
   cd /home/juls/terraform_proxmox/terraform_proxmox/tabletop-exercises
   helm install webapp helm-charts/broken-service -n exercise-02
   ```

3. **Verify pods are running:**
   ```bash
   kubectl get pods -n exercise-02
   ```

4. **Try to access the service (this will fail):**
   ```bash
   kubectl run curl-test --image=curlimages/curl:latest --rm -it --restart=Never \
     -n exercise-02 -- curl http://webapp-service:80 --max-time 5
   ```

## Your Mission

### Phase 1: Verify Application Layer (5 minutes)
- Confirm pods are running
- Test direct pod connectivity (bypassing service)
- Verify the application is listening on the expected port

### Phase 2: Investigate Service Layer (10 minutes)
- Examine service configuration
- Check service endpoints
- Identify the port mapping issue

### Phase 3: Fix and Validate (5-10 minutes)
- Correct the service configuration via Helm
- Test connectivity through the service
- Verify endpoints are correct

## Hints

<details>
<summary>Hint 1: How to test if pods are healthy?</summary>

Access a pod directly to see if the app is working:
```bash
kubectl exec -it <pod-name> -n exercise-02 -- wget -O- http://localhost:8080
```

</details>

<details>
<summary>Hint 2: How to check service configuration?</summary>

Look at the service definition:
```bash
kubectl describe svc webapp-service -n exercise-02
kubectl get svc webapp-service -n exercise-02 -o yaml
```

Pay attention to `Port`, `TargetPort`, and `Endpoints`.

</details>

<details>
<summary>Hint 3: What are endpoints?</summary>

Endpoints show which pod IPs the service is routing to:
```bash
kubectl get endpoints webapp-service -n exercise-02
```

If endpoints are empty or wrong, the service can't route traffic.

</details>

<details>
<summary>Hint 4: What's the port mismatch?</summary>

Check:
- What port does the container listen on? (8080)
- What port is the service targeting? (Look in service definition)
- Do they match?

</details>

<details>
<summary>Hint 5: How to debug with a test pod?</summary>

Deploy a debug pod to test connectivity:
```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -n exercise-02 -- /bin/bash
# Inside the pod:
curl http://webapp-service:80
nslookup webapp-service
```

</details>

## Solution

Only look at this after attempting the exercise yourself!

[Solution Guide](solution.md)

## Cleanup

```bash
helm uninstall webapp -n exercise-02
kubectl delete namespace exercise-02
```

## What You Learned

After completing this scenario, you should understand:

- ✅ The difference between `port`, `targetPort`, and `containerPort`
- ✅ How Kubernetes Services route traffic to pods
- ✅ How to use debug pods for network troubleshooting
- ✅ How to verify service endpoints
- ✅ How to test pod connectivity directly vs. through a service
- ✅ The importance of port configuration matching

## Next Steps

Continue to **[Scenario 3: Image Pull Nightmare](../03-image-pull/README.md)** for image troubleshooting practice.

## Additional Challenges

1. **Modify the scenario:**
   - Change the container port to 9090 and update both deployment and service
   - Add a second container to the pod and expose it through the same service
   - Use a NodePort service and access from outside the cluster

2. **Test different service types:**
   - Change from ClusterIP to NodePort
   - Try LoadBalancer (if supported)
   - Experiment with headless services (clusterIP: None)

3. **Advanced debugging:**
   - Use `tcpdump` in a debug pod to see traffic
   - Check iptables rules that Kubernetes creates
   - Trace packet flow from service to pod
