# 6-netpolicy Helm Chart

## Purpose

This chart is **intentionally broken** for training. Traffic to the Pod is blocked by a deny-all `NetworkPolicy`.

## The Problem

- The chart creates a `NetworkPolicy` with:
  - `policyTypes: [Ingress, Egress]`
  - `ingress: []` and `egress: []`
- Result: no inbound/outbound traffic is allowed to the selected Pods

## How to Reproduce

```bash
helm install netpolicy . -n exercise-01 --create-namespace
kubectl get networkpolicy -n exercise-01
kubectl describe networkpolicy -n exercise-01
```

## Fix

Allow traffic (or remove the deny-all policy).

### Quick fix (allow all ingress to port 80)

Create an allow policy in the same namespace:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: netpolicy-allow-http
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: netpolicy-app
  policyTypes:
  - Ingress
  ingress:
  - from: []
    ports:
    - protocol: TCP
      port: 80
```

Apply it:

```bash
kubectl apply -n exercise-01 -f allow.yaml
```

### Chart-level fix

Edit the chart to remove/relax the deny-all `NetworkPolicy` (it’s embedded in `templates/deployment.yaml`).
