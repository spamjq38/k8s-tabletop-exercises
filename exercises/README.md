# Tabletop Exercises - Quick Reference

## 🎯 Getting Started

**IMPORTANT:** First-time setup requires deploying exercises from your local machine:

0. **Deploy exercises** (run on your local machine, not the cluster):
   ```bash
   cd /home/juls/terraform_proxmox/terraform_proxmox
   bash deploy_exercises.sh
   ```
   ℹ️ This copies all exercise materials to the control plane.

1. **SSH to the control plane:**
   ```bash
   ssh root@192.168.122.100
   # Password: 2992629926
   ```

2. **Navigate to exercises:**
   ```bash
   cd /root/tabletop-exercises
   ./start-exercise.sh
   ```

3. **Choose a scenario and start learning!**

## 📋 Available Scenarios

### Scenario 1: Memory Limit Mayhem ⭐
**What you'll learn:** Diagnosing OOMKilled pods, resource limits
**Time:** 15-20 minutes
```bash
cd scenarios/01-crashloop
cat README.md
```

### Scenario 2: The Unreachable Service ⭐⭐
**What you'll learn:** Service networking, port troubleshooting
**Time:** 20-25 minutes
```bash
cd scenarios/02-service-port
cat README.md
```

### Scenario 3: Helm Rollback Practice ⭐
**What you'll learn:** Helm upgrades, rollbacks, revision management
**Time:** 15-20 minutes
```bash
./helm-rollback-practice.sh
cat helm-rollback-summary.md
```

### Scenario 4: Image Pull Nightmare ⭐ (Coming Soon)
**What you'll learn:** Image troubleshooting, registry issues
**Time:** 15 minutes

### Scenario 4: Configuration Chaos ⭐⭐ (Coming Soon)
**What you'll learn:** ConfigMaps, environment variables
**Time:** 25-30 minutes

### Scenario 5: Scheduling Standstill ⭐⭐⭐ (Coming Soon)
**What you'll learn:** Node selectors, taints/tolerations
**Time:** 30-35 minutes

## 🛠️ Essential Commands

### Quick Diagnostics
```bash
kubectl get pods -A                    # See all pods
kubectl describe pod <name>            # Pod details
kubectl logs <pod> --previous          # Crashed container logs
kubectl get events --sort-by='.lastTimestamp'  # Recent events
```

### Helm Operations
```bash
helm list -A                           # All releases
helm install <name> <chart> -n <ns>    # Deploy
helm upgrade <name> <chart> -n <ns>    # Fix issues
helm uninstall <name> -n <ns>          # Cleanup
```

### Namespace Management
```bash
kubectl create namespace exercise-01   # Create namespace
kubens exercise-01                     # Switch to namespace
kubens                                 # List all namespaces
```

## 📚 Documentation

- **[Main Guide](../../TABLETOP_EXERCISES.md)** - Complete overview
- **[Troubleshooting Playbook](TROUBLESHOOTING_PLAYBOOK.md)** - Command reference
- **Scenario READMEs** - Detailed instructions for each exercise

## 🎓 Learning Path

**Beginners:**
1. Read the [Main Guide](../../TABLETOP_EXERCISES.md) overview
2. Start with Scenario 1 (easiest)
3. Use the [Troubleshooting Playbook](TROUBLESHOOTING_PLAYBOOK.md) as reference
4. Don't look at solutions until you've tried!

**Experienced Users:**
1. Jump to Scenario 5 for a challenge
2. Try multiple scenarios in parallel
3. Create your own broken charts

## 💡 Tips

- **Create dedicated namespaces** for each scenario
- **Use kubens** to switch between namespaces quickly
- **Check the solution** only after attempting yourself
- **Clean up** after each scenario to avoid conflicts
- **Document** what you learn

## 🚀 Deployment Workflow

Each scenario follows this pattern:

```bash
# 1. Create namespace
kubectl create namespace exercise-01
kubens exercise-01

# 2. Deploy broken app
helm install my-app helm-charts/<chart-name> -n exercise-01

# 3. Diagnose the issue
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# 4. Fix via Helm
helm upgrade my-app helm-charts/<chart-name> -f fixed-values.yaml

# 5. Verify
kubectl get pods  # Should be Running

# 6. Cleanup
helm uninstall my-app -n exercise-01
kubectl delete namespace exercise-01
```

## 🆘 Getting Stuck?

1. Check the hints in each scenario's README
2. Review the [Troubleshooting Playbook](TROUBLESHOOTING_PLAYBOOK.md)
3. Remember: the goal is to learn, not to finish fast
4. Take breaks and come back with fresh eyes

## 📊 Track Your Progress

Create a progress log:
```bash
echo "# My Tabletop Progress" > ~/progress.md
echo "- [ ] Scenario 1: Memory Limit Mayhem" >> ~/progress.md
echo "- [ ] Scenario 2: The Unreachable Service" >> ~/progress.md
# ... etc
```

## 🎉 Next Steps

After completing all scenarios:
- Create your own broken charts
- Practice in time-attack mode
- Deploy via ArgoCD for GitOps practice
- Share what you learned with your team

---

**Happy Troubleshooting!** Remember: Every error is a learning opportunity. 🚀
