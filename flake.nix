{
  inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  inputs.determinate.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self
    , determinate
    , nixpkgs
    ,
    }:
    let
      system = "x86_64-linux";
      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          determinate.nixosModules.default
          ({ lib, ... }:
            {
              nix.registry.nixpkgs.to = lib.mkForce (
                {
                  type = "path";
                  path = nixpkgs.outPath;
                }
                // lib.filterAttrs (n: _: n == "lastModified" || n == "rev" || n == "narHash") nixpkgs
              );
            }
          )
          ./configuration.nix
        ];
      };
      pkgs = nixos.pkgs;
      image = pkgs.dockerTools.buildLayeredImageWithNixDb {
        name = "nixos-in-podman";
        tag = "latest";
        contents = [ nixos.config.system.build.toplevel ];
        extraCommands = ''
          rm etc
          mkdir -p proc sys dev etc
        '';
        config = {
          Entrypoint = [ "/init" ];
          Env = [
            "PATH=/root/.local/bin:/run/wrappers/bin:/root/.nix-profile/bin:/nix/profile/bin:/root/.local/state/nix/profile/bin:/etc/profiles/per-user/root/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
            "TERM=xterm-256color"
            "USER=root"
          ];
          Labels = {
            "devcontainer.metadata" = builtins.toJSON [
              {
                remoteEnv.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
                remoteEnv.PATH = "/home/terrorjack/.local/bin:/run/wrappers/bin:/home/terrorjack/.nix-profile/bin:/nix/profile/bin:/home/terrorjack/.local/state/nix/profile/bin:/etc/profiles/per-user/terrorjack/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
                remoteEnv.USER = "terrorjack";
                remoteUser = "terrorjack";
              }
            ];
          };
          StopSignal = "SIGRTMIN+3";
          User = "0:0";
        };
        compressor = "none";
      };
    in
    {
      nixosConfigurations."nixos-in-podman" = nixos;

      packages.${system}.default = image;
    };

  nixConfig = {
    extra-substituters = [
      "https://install.determinate.systems"
    ];
    extra-trusted-public-keys = [
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio="
      "cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU="
      "cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU="
      "cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8="
      "cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ="
      "cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o="
      "cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y="
    ];
  };
}
