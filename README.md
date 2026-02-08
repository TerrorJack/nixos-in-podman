# `nixos-in-podman`

My personal playground project for running NixOS in a rootless podman
container. Could also be useful as a template for you to adapt and use
if you have similar needs.

## How to use

- Modify [`configuration.nix`](./configuration.nix) for your own
  needs.
- Run `./boot.sh` to rebuild and boot it.
- Run `./fastboot.sh` to boot the already built image without
  rebuilding.
- Run `sudo poweroff` within the container to stop the container, or
  use `podman stop`.

## Features

- NixOS with systemd experience in a rootless podman container.
- Self-contained nix store in layered container image, doesn't bind
  mount & require host nix store.
- podman-in-podman with krun & multiarch qemu binfmt support.
- Can be used as vscode devcontainer out of the box; vscode auto
  selects the default non-root user.
- Can be built on non-NixOS hosts with nix, without needing podman.
- Can be deployed on non-NixOS hosts with podman, without needing nix.

## Use cases

- Quickly experiment with NixOS modules and services without VM
  overhead or redeploying a NixOS host.
- Sandbox of coding agents.
- Running NixOS on non-NixOS hosts where reinstalling NixOS is not an
  option.

## Comparisons

### [`microvm.nix`](https://github.com/microvm-nix/microvm.nix)

`microvm.nix` and other VM-based solutions are a different tradeoff of
isolation and efficiency. They provide stronger isolation guarantees,
at the cost of:

- Even with KVM and virtio, they boot up slower than systemd in
  container, with slower host filesystem interop and networking.
- Even with ballooning, they take more RAM, especially with many
  instances booted up at once; this can be mitigated by KSM but that
  has its own CPU overhead.
- Deployment requires host KVM support, which may not be present in
  many cases (e.g. cheap VPS providers).

I personally find containers a sweeter spot of isolation and
efficiency, for the use cases I care about.

### [`nixos-container`](https://nixos.org/manual/nixos/stable/#ch-containers)

`nixos-container` doesn't have rootless mode yet; it should be
possible given systemd-nspawn already supports rootless, but real work
needs to be done to make `nixos-container` take advantage of that. For
me it's the main issue. Also, it does require a NixOS host both at
build and deployment time. Otherwise it's great.

### [`nixos-rebuild build-image`](https://nixos.org/manual/nixos/stable/#sec-image-nixos-rebuild-build-image)

`nixos-rebuild build-image` does not provide a container image format;
the `oci` variant is actually for Oracle Cloud Infrastructure (lmao).
Its former project
[`nixos-generators`](https://github.com/nix-community/nixos-generators),
does provide a `docker` format, but `nixos-generators` is already
archived.

### [`nixos/nix`](https://github.com/nixos/nix/pkgs/container/nix)

`nixos/nix` image only provides nix, not NixOS with systemd
experience. For CI builds that only require daemonless nix builds and
doesn't require NixOS/systemd, it's simpler to use than this image.
