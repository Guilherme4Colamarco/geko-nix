{
  description = "Configuracao NixOS do geko";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nix-flatpak.url = "github:gmodena/nix-flatpak";
  inputs.home-manager = {
    url = "github:nix-community/home-manager/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.astrovim = {
    url = "github:AstroNvim/template";
    flake = false;
  };

  inputs.hermesAgent.url = "github:NousResearch/hermes-agent";
  inputs.hermesDesktop = {
    url = "path:./agents";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.hermesAgent.follows = "hermesAgent";
  };
  inputs.ryoku = {
    url = "github:aethctl/Ryoku-on-NixOS/main";
    inputs.hermesAgent.follows = "hermesDesktop";
  };

  outputs = { ryoku, hermesAgent, nixpkgs, nixpkgs-unstable, nix-flatpak, home-manager, astrovim, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit hermesAgent;
        unstablePkgs = import nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };
      modules = [
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        ryoku.nixosModules.default
        ./ryoku.nix
        ./agents/hermes.nix
        ./configuration.nix
        ./programs/stables.nix
        ./programs/unstables.nix
        ./programs/games.nix
        ./programs/flatpaks.nix
        ./programs/development.nix
        ({ pkgs, ... }: {
          home-manager.users.geko = {
            home.stateVersion = "26.05";
            home.packages = [ pkgs.mcp-nixos ];
            xdg.enable = true;
            xdg.configFile."astronvim".source = pkgs.runCommand "astronvim-config" { } ''
              cp -r ${astrovim} $out
              chmod -R u+w $out
              substituteInPlace $out/lua/lazy_setup.lua \
                --replace-fail 'ui = { backdrop = 100 },' \
                  'lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json", ui = { backdrop = 100 },'
            '';
          };
        })
        ({ lib, ... }: {
          programs.ryoku.updateFlake = "/home/geko/Documentos/geko-nix";

          xdg.mime.defaultApplications = {
            "text/html" = "brave-origin.desktop";
            "x-scheme-handler/http" = "brave-origin.desktop";
            "x-scheme-handler/https" = "brave-origin.desktop";
          };

          # Ryoku's environment.etc entry conflicts with NixOS's
          # /etc/systemd/user symlink. Add the setting as a user unit drop-in.
          environment.etc."systemd/user/xdg-desktop-portal-gnome.service.d/10-ryoku.conf".enable =
            lib.mkForce false;
          systemd.user.services.xdg-desktop-portal-gnome = {
            overrideStrategy = "asDropin";
            serviceConfig.UnsetEnvironment = "GDK_BACKEND";
          };
        })
      ];
    };
  };
}
