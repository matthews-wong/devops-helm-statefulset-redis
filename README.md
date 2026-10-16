# devops-helm-statefulset-redis

A small Helm chart that runs a single Redis instance as a StatefulSet with
a headless Service, a persistent volume and a ConfigMap-driven `redis.conf`.

It is meant as a compact reference for the StatefulSet parts of Helm that
Deployment-based charts never touch: stable network identity,
`volumeClaimTemplates`, and rolling the pod when its config changes.

## Layout

```
charts/redis/
  Chart.yaml
  values.yaml          defaults
  values-dev.yaml      small, no persistence
  values-prod.yaml     persistent, larger limits
  values.schema.json   rejects :latest and bad sizes
  templates/
```

## Usage

```bash
helm template cache charts/redis -f charts/redis/values-dev.yaml
helm install cache charts/redis -f charts/redis/values-prod.yaml
```

## Validate

Needs `helm` and `kubeconform` on the PATH:

```bash
make validate
```
