#!/usr/bin/env bash

set -euo pipefail

podman rmi -f nixos-in-podman || true

nix flake update

podman import \
  --change 'CMD=["/init"]' \
  --change STOPSIGNAL=SIGRTMIN+3 \
  --change USER=0 \
  "$(nix build --no-link --print-out-paths .)/tarball/nixos-system-x86_64-linux.tar" \
  nixos-in-podman

# add --privileged for podman in container or binfmt or polkit

exec podman run -it --rm \
  --systemd always \
  --userns keep-id:uid=1000,gid=100 \
  --tmpfs /run/wrappers:rw,exec,suid,mode=755 \
  --tmpfs /nix/var/nix/builds \
  --name nixos-in-podman \
  --hostname nixos-in-podman \
  --no-hostname \
  --no-hosts \
  nixos-in-podman
