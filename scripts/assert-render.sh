#!/usr/bin/env bash
# Render the chart with different values and assert on the output.
set -euo pipefail

CHART=${CHART:-charts/redis}
RELEASE=cache

render() {
  helm template "$RELEASE" "$CHART" "$@"
}

checksum() {
  render "$@" | grep 'checksum/config:' | awk '{print $2}'
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# The pod must roll when redis.conf changes, and only then.
base=$(checksum)
[ -n "$base" ] || fail "checksum/config annotation missing from the pod template"
changed=$(checksum --set config="maxmemory 64mb")
[ "$base" != "$changed" ] || fail "checksum/config did not change with config (still $base)"
[ "$base" = "$(checksum)" ] || fail "checksum/config is not stable across identical renders"

# persistence.enabled=false swaps the claim for an emptyDir.
if render --set persistence.enabled=false | grep -q 'volumeClaimTemplates'; then
  fail "volumeClaimTemplates rendered with persistence.enabled=false"
fi
render --set persistence.enabled=false | grep -q 'emptyDir' \
  || fail "no emptyDir data volume with persistence.enabled=false"
render | grep -q 'volumeClaimTemplates' \
  || fail "volumeClaimTemplates missing with default persistence"

# The PodDisruptionBudget is opt-in and takes exactly one budget field.
render | grep -q 'kind: PodDisruptionBudget' \
  && fail "PodDisruptionBudget rendered by default"
render --set podDisruptionBudget.enabled=true | grep -q 'maxUnavailable: 1' \
  || fail "default PodDisruptionBudget should set maxUnavailable: 1"
render --set podDisruptionBudget.enabled=true --set podDisruptionBudget.minAvailable=1 \
  | grep -q 'minAvailable: 1' || fail "minAvailable not rendered"
if render --set podDisruptionBudget.enabled=true \
  --set podDisruptionBudget.minAvailable=1 \
  --set podDisruptionBudget.maxUnavailable=1 >/dev/null 2>&1; then
  fail "PodDisruptionBudget accepted both minAvailable and maxUnavailable"
fi

echo "render assertions passed"
