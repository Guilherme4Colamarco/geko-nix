{
  description = "NixOS do geko com desktop modular Serpantinum";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chatgpt-desktop-app = {
      url = "github:poeck/chatgpt-desktop-app-nix-flake/d23d08e1275566612fbac7487f18771dde415af2";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    claude-desktop-app = {
      url = "github:poeck/claude-desktop-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    ecc = {
      url = "github:affaan-m/ECC/ef648e01899ba3e8dc6371642deaaf64b4477775";
      flake = false;
    };
    pstack = {
      url = "github:shrimpwtf/oh-my-pstack/fc0eabd25f21b194a336b640e75e29c252382866";
      flake = false;
    };
    astrovim = { url = "github:AstroNvim/template"; flake = false; };
    pleamar-wm = {
      url = "github:k4ditano/pleamar-wm/548b3fc226e65128770eef832b26142b33e23729";
      inputs.marea.url = "github:k4ditano/marea-plm/d3c5398c99eaad9bb045d7f0838efd849fea2c6f";
    };
    serpantinum.url = "github:ilyamiro/serpantinum/225ea62e0545e25fa813d8409390d73588575b3c";
  };
  outputs = inputs@{ nixpkgs, home-manager, nix-flatpak, serpantinum, ... }: let
    system = "x86_64-linux";
    unstablePkgs = import inputs.nixpkgs-unstable { inherit system; config.allowUnfree = true; };
    desktopPkgs = import serpantinum.inputs.nixpkgs { inherit system; config.allowUnfree = true; };
    mkDesktop = desktop: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs unstablePkgs desktopPkgs; desktopProfile = desktop; };
      modules = [
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        ./configuration.nix
        ./modules/core
        ./modules/core/usuario.nix
        ./modules/hardware/nvidia-desktop.nix
        ./modules/services/docker.nix
        ./modules/services/homelab.nix
        ./modules/desktop/options.nix
        ./modules/desktop/gaming.nix
        ./programs/stables.nix
        ./programs/unstables.nix
        ./programs/development.nix
        ./programs/flatpaks.nix
        ./programs/faculdade.nix
        ({ config, ... }: {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "before-geko-nix";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.${config.geko.usuario.nome} = import ./home;
        })
      ] ++ (if desktop == "serpantinum" then [
        serpantinum.nixosModules.default ./modules/desktop/serpantinum.nix
      ] else if desktop == "pleamar" then [
        inputs.pleamar-wm.nixosModules.default ./modules/desktop/pleamar.nix
      ] else if desktop == "niri" then [
        ./modules/desktop/niri.nix
      ] else [
        ./modules/desktop/hyprland.nix
      ]);
    };
  in {
    checks.${system} = nixpkgs.lib.genAttrs [ "honey-pleamar" "honey-pleamar-core" "honey-niri" "honey-hyprland" ] (name:
      import ./tests/honey-vm.nix {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit inputs desktopPkgs unstablePkgs;
        compositor = if name == "honey-pleamar-core" then "pleamar" else nixpkgs.lib.removePrefix "honey-" name;
        requireCapture = name != "honey-pleamar-core";
      });
    nixosConfigurations.nixos = mkDesktop "serpantinum";
    nixosConfigurations.serpantinum = mkDesktop "serpantinum";
    nixosConfigurations.pleamar = mkDesktop "pleamar";
    nixosConfigurations.niri = mkDesktop "niri";
    nixosConfigurations.hyprland = mkDesktop "hyprland";
  };
}
