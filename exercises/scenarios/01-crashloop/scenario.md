# Scenario Background: The Midnight Page

## The Situation

It's 2 AM on a Tuesday. You're the on-call engineer for DataFlow Corp's data processing platform. Your phone buzzes with an alert:

```
🚨 CRITICAL: data-processor pods crashing in production
Namespace: exercise-01
Current state: CrashLoopBackOff
Impact: Data processing pipeline halted
Customer Impact: HIGH - Reports delayed
```

## The Context

Earlier today, your colleague Jake from the operations team made what he called "optimization changes" to the production environment. He sent this Slack message at 5 PM:

> "Hey team 👋 Just tightened up resource limits on all production pods to save cluster capacity. We were way over-provisioned. Changes deployed to prod. Have a great evening!"

You were in meetings all afternoon and didn't see the message until now.

## The Pressure

Your CTO just joined the incident Slack channel:
> "What's our ETA on fix? We have customers asking why their daily reports haven't run."

Your manager adds:
> "Let me know what you need. We can roll back if necessary, but need root cause identified."

## Your Task

You need to:
1. Quickly diagnose what Jake changed and why it's causing crashes
2. Determine the minimum resources the app actually needs
3. Apply a fix that's properly tested (not just "make limits huge")
4. Document what went wrong so this doesn't happen again

## What You Know

From the deployment documentation (which Jake apparently didn't read):
- The data processor loads customer data into memory for transformation
- Typical workload processes 100-500MB files
- Development environment has no resource limits (unlimited resources)
- This is why it worked fine in dev but fails in prod

## The Clock is Ticking

You have 15-20 minutes before the CTO escalates this to the VP of Engineering.

Time to diagnose and fix this!

---

*This scenario is fictional but represents a very common real-world incident: well-meaning "optimizations" that don't account for actual application requirements.*
