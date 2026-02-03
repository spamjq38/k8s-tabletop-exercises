#!/bin/bash
# Cleanup script - removes labels and taints added by setup

set -e

echo "════════════════════════════════════════════════"
echo "  Cleaning up Scheduling Exercise"
echo "════════════════════════════════════════════════"
echo ""

# Get node names
CONTROL_NODE=$(kubectl get nodes -o jsonpath='{.items[?(@.metadata.labels.node-role\.kubernetes\.io/control-plane)].metadata.name}')
WORKER_NODE=$(kubectl get nodes -o jsonpath='{.items[?(!@.metadata.labels.node-role\.kubernetes\.io/control-plane)].metadata.name}')

echo "Removing labels from nodes..."
kubectl label node $WORKER_NODE environment- --ignore-not-found
kubectl label node $WORKER_NODE disktype- --ignore-not-found
kubectl label node $CONTROL_NODE environment- --ignore-not-found 2>/dev/null || true
echo "✓ Labels removed"
echo ""

echo "Removing custom taint from control plane..."
kubectl taint node $CONTROL_NODE special:NoSchedule- --ignore-not-found 2>/dev/null || echo "  (Taint not found)"
echo "✓ Custom taint removed"
echo ""

echo "✓ Cleanup complete!"
