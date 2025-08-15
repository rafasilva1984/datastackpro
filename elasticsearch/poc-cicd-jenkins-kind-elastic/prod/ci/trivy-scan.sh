#!/usr/bin/env bash
set -euo pipefail
IMAGE="$1"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.54.1   image --exit-code 1 --severity CRITICAL,HIGH "$IMAGE"
