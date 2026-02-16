# helm-charts-new

This directory is the **single source of truth** for the tabletop exercise Helm charts.

## Auto-sync to GitHub

Every time you run the deployment scripts, these charts are mirrored into the GitHub repo:

- https://github.com/spamjq38/k8s-tabletop-exercises
  - Path: `helm-charts/`

The sync happens from this repo’s deployment scripts via:

- `sync_helm_charts_to_k8s_tabletop_exercises.sh`

## Notes

- Only content under `helm-charts-new/` is synced.
- Files like `deploy.sh` are **not** synced to `k8s-tabletop-exercises`.
