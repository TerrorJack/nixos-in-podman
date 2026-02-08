{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self
    , nixpkgs
    ,
    }:
    let
      system = "x86_64-linux";
      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
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
}
