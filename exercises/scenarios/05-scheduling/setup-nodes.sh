#!/bin/bash
# Setup script for scheduling exercise
# This adds labels and taints to nodes for the exercise

set -e

echo "════════════════════════════════════════════════"
echo "  Setting up nodes for Scheduling Exercise"
echo "════════════════════════════════════════════════"
echo ""

# Get node names
CONTROL_NODE=$(kubectl get nodes -o jsonpath='{.items[?(@.metadata.labels.node-role\.kubernetes\.io/control-plane)].metadata.name}')
WORKER_NODE=$(kubectl get nodes -o jsonpath='{.items[?(!@.metadata.labels.node-role\.kubernetes\.io/control-plane)].metadata.name}')

echo "Control plane node: $CONTROL_NODE"
echo "Worker node: $WORKER_NODE"
echo ""

# Add labels for node selector exercises
echo "Adding labels to nodes..."
kubectl label node $WORKER_NODE environment=staging --overwrite
kubectl label node $WORKER_NODE disktype=ssd --overwrite
kubectl label node $CONTROL_NODE environment=production --overwrite 2>/dev/null || true
echo "✓ Labels added"
echo ""

# Add taint to control plane (if not already there)
echo "Ensuring control plane has special taint..."
kubectl taint node $CONTROL_NODE special=true:NoSchedule --overwrite 2>/dev/null || echo "  (Taint already exists)"
echo "✓ Control plane tainted"
echo ""

# Show current node status
echo "════════════════════════════════════════════════"
echo "  Current Node Configuration"
echo "════════════════════════════════════════════════"
echo ""
echo "Node Labels:"
kubectl get nodes --show-labels
echo ""
echo "Node Taints:"
kubectl describe nodes | grep -E "^Name:|Taints:" | grep -A 1 "Name:"
echo ""
echo "✓ Setup complete! Now run: kubectl apply -f broken-scheduling.yaml"
