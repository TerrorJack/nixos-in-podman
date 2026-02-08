#!/usr/bin/env bash

set -euo pipefail

# add --privileged for:
#
# - podman in container
# - binfmt_misc emulators
# - polkit
# - perf stat
# - nixos-rebuild switch

exec podman run -it --rm \
  --systemd always \
  --userns keep-id:uid=1000,gid=100 \
  --pids-limit -1 \
  --network host \
  --tmpfs /run/wrappers:rw,exec,suid,mode=755 \
  --tmpfs /nix/var/log \
  --tmpfs /nix/var/nix/builds \
  --tmpfs /tmp \
  --tmpfs /var/tmp \
  --device /dev/kvm \
  --name nixos-in-podman \
  --hostname nixos-in-podman \
  --no-hostname \
  --no-hosts \
  --privileged \
  nixos-in-podman
