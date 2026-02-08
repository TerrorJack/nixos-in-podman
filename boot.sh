#!/usr/bin/env bash

set -euo pipefail

podman rmi -f nixos-in-podman || true

nix flake update

podman load -i "$(nix build --no-link --print-out-paths .)"

exec ./fastboot.sh
