# 6-netpolicy Helm Chart

## Purpose

This chart is **intentionally broken** for training. Traffic to the Pod is blocked by a deny-all `NetworkPolicy`.

## The Problem

- The chart creates a `NetworkPolicy` with:
  - `policyTypes: [Ingress, Egress]`
  - `ingress: []` and `egress: []`
- Result: no inbound/outbound traffic is allowed to the selected Pods

## How to Reproduce

`exercise-namespace` below is a Kubernetes namespace name (not a local repo folder). It is created automatically by `--create-namespace`.

Commands below must be run from a machine where this chart directory exists.

```bash
helm install netpolicy . -n exercise-namespace --create-namespace
kubectl get networkpolicy -n exercise-namespace
kubectl describe networkpolicy -n exercise-namespace
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
kubectl apply -n exercise-namespace -f allow.yaml
```

### Option 1 (Recommended): GitOps fix (persistent with ArgoCD)

In this environment, ArgoCD tracks:

- **Target Revision**: `argocd-active`
- **Path**: `helm-charts-new/6-netpolicy`

So the persistent fix is:

```bash
cd /home/juls/terraform_proxmox/terraform_proxmox
git checkout argocd-active

# edit: helm-charts-new/6-netpolicy/templates/deployment.yaml
git add helm-charts-new/6-netpolicy/templates/deployment.yaml
git commit -m "fix(netpolicy): allow required ingress traffic"
git push origin argocd-active
```

Then in ArgoCD, sync app `netpolicy-helm` (or wait for auto-sync).

### Option 2: Run from laptop over SSH (temporary override)

```bash
cat <<'EOF' | ssh root@192.168.122.100 'kubectl apply -n exercise-namespace -f -'
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
EOF
```

### Chart-level fix

Edit the chart to remove/relax the deny-all `NetworkPolicy` (it’s embedded in `templates/deployment.yaml`).
