{ config
, lib
, pkgs
, modulesPath
, ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/docker-image.nix")
  ];

  boot.isNspawnContainer = true;

  boot.postBootCommands = lib.mkAfter ''
    # In rootless outer podman, systemd's binfmt automount (autofs) can fail
    # with EPERM. Mount binfmt_misc directly and register handlers here.
    if ! ${pkgs.util-linux}/bin/mountpoint -q /proc/sys/fs/binfmt_misc; then
      ${pkgs.util-linux}/bin/mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc || true
    fi
    if [ -e /proc/sys/fs/binfmt_misc/register ] && [ -x /run/current-system/systemd/lib/systemd/systemd-binfmt ]; then
      /run/current-system/systemd/lib/systemd/systemd-binfmt || true
    fi

    /run/current-system/sw/bin/determinate-nixd init
  '';

  console.enable = true;

  services.getty.autologinUser = "terrorjack";

  services.nscd.enableNsncd = false;

  networking.useDHCP = false;

  systemd.oomd.enable = false;

  networking.hostName = "nixos-in-podman";

  system.fsPackages = [ pkgs.btrfs-progs ];

  environment.etc = {
    "nixos/flake.nix" = {
      source = ./flake.nix;
      mode = "0644";
    };
    "nixos/flake.lock" = {
      source = ./flake.lock;
      mode = "0644";
    };
    "nixos/configuration.nix" = {
      source = ./configuration.nix;
      mode = "0644";
    };
  };

  environment.localBinInPath = true;

  environment.memoryAllocator.provider = "mimalloc";

  time.timeZone = "Europe/Paris";

  systemd.settings.Manager.DefaultLimitNOFILE = 1048576;

  services.journald.extraConfig = "Compress=false";

  security.sudo.execWheelOnly = true;
  security.sudo.wheelNeedsPassword = false;

  security.doas.enable = true;
  security.doas.wheelNeedsPassword = false;

  security.polkit.enable = true;

  users.allowNoPasswordLogin = true;
  users.mutableUsers = false;

  users.users.terrorjack = {
    uid = 1000;
    password = "";
    isNormalUser = true;
    linger = true;
    extraGroups = [
      "kvm"
      "podman"
      "render"
      "wheel"
    ];
    subUidRanges = [
      {
        startUid = 1;
        count = 999;
      }
      {
        startUid = 1001;
        count = 64536;
      }
    ];
    subGidRanges = [
      {
        startGid = 1;
        count = 99;
      }
      {
        startGid = 101;
        count = 65436;
      }
    ];
  };

  nix.channel.enable = false;
  nix.daemonIOSchedPriority = 7;
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";
  nix.settings.accept-flake-config = true;
  nix.settings.compress-build-log = false;
  nix.settings.download-buffer-size = 134217728;
  nix.settings.http-connections = 0;
  nix.settings.eval-cores = 0;
  nix.settings.extra-experimental-features = [
    "parallel-eval"
  ];
  nix.settings.extra-trusted-users = [
    "@wheel"
  ];
  nix.settings.sandbox-fallback = lib.mkForce true;
  nix.settings.use-xdg-base-directories = true;
  systemd.services.nix-daemon.serviceConfig.Nice = 19;

  virtualisation.podman.enable = true;
  virtualisation.containers.enable = true;
  virtualisation.containers.containersConf.settings.containers.mounts = [
    "type=tmpfs,destination=/tmp"
  ];
  virtualisation.containers.containersConf.settings.containers.pids_limit = 0;
  virtualisation.containers.containersConf.settings.containers.shm_size = "1G";
  virtualisation.containers.registries.search = [ "docker.io" ];
  virtualisation.containers.storage.settings.storage.driver = "btrfs";

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.binfmt.preferStaticEmulators = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (self: super: {
      crun = super.crun.overrideAttrs (attrs: {
        buildInputs = (attrs.buildInputs or [ ]) ++ [ self.libkrun ];
        nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ [ self.makeWrapper ];
        configureFlags = (attrs.configureFlags or [ ]) ++ [ "--with-libkrun" ];
        postFixup = (attrs.postFixup or "") + ''
          # crun's libkrun integration uses dlopen(), so ensure libkrun is in
          # the runtime library search path when invoked as `krun`.
          wrapProgram $out/bin/crun \
            --prefix LD_LIBRARY_PATH : ${
              lib.makeLibraryPath [
                self.libkrun
              ]
            }
        '';
      });
    })
  ];

  services.postgresql.enable = true;
  services.postgresql.enableJIT = true;
  systemd.services.postgresql.serviceConfig.User = lib.mkForce "terrorjack";
  systemd.services.postgresql.serviceConfig.Group = lib.mkForce "users";

  programs.htop.enable = true;
  programs.htop.settings = {
    hide_userland_threads = true;
    tree_view = true;
  };

  programs.nano.nanorc = ''
    set autoindent
    set breaklonglines
    set tabsize 2
    set tabstospaces
  '';

  system.stateVersion = "26.05";
}
