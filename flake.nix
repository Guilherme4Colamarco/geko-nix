# Ponto de entrada. Declara as entradas (inputs), monta o sistema de cada perfil
# (nixos, serpantinum, pleamar, niri, hyprland, cosmic) e os testes de VM do Honey (checks).
{
  description = "NixOS do geko com desktop modular Serpantinum";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Alias mantido para os módulos e flakes que já usam esse nome.
    nixpkgs-unstable.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chatgpt-desktop-app = {
      url = "github:poeck/chatgpt-desktop-app-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    claude-desktop-app = {
      url = "github:poeck/claude-desktop-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
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
    desktopPkgs = unstablePkgs;
    # Cada perfil de desktop é um arquivo em desktops/ (sistema + usuário juntos).
    desktops = {
      serpantinum = ./desktops/serpantinum.nix;
      pleamar = ./desktops/pleamar.nix;
      niri = ./desktops/niri-honey.nix;
      hyprland = ./desktops/hyprland-honey.nix;
      cosmic = ./desktops/cosmic.nix;
    };
    mkDesktop = desktop: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs unstablePkgs desktopPkgs; desktopProfile = desktop; };
      modules = [
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        ./configuration.nix
        ./modules/core
        ./modules/core/usuario.nix
        ./modules/core/comunidade.nix
        ./modules/hardware/nvidia-desktop.nix
        ./modules/services/homelab.nix
        ./modules/services/ghidra-mcp.nix
        ./modules/desktop/options.nix
        ./programs
        ({ config, ... }: {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "before-geko-nix";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.${config.geko.usuario.nome} = import ./home;
        })
      ] ++ [ desktops.${desktop} ];
    };
  in {
    packages.${system} = let
      modTools = unstablePkgs.callPackage ./pkgs/game-modding { };
    in {
      inherit (modTools) universal-modder rea ghidra-mcp ida-mcp;
    };
    checks.${system} = nixpkgs.lib.genAttrs [ "honey-pleamar" "honey-pleamar-core" "honey-niri" "honey-hyprland" ] (name:
      import ./tests/honey-vm.nix {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit inputs desktopPkgs unstablePkgs;
        compositor = if name == "honey-pleamar-core" then "pleamar" else nixpkgs.lib.removePrefix "honey-" name;
        requireCapture = name != "honey-pleamar-core";
      }) // {
        software = import ./tests/software.nix { inherit inputs; pkgs = unstablePkgs; };
        software-personal = import ./tests/software-personal.nix {
          pkgs = unstablePkgs; configuration = mkDesktop "serpantinum";
        };
      };
    nixosConfigurations.nixos = mkDesktop "serpantinum";
    nixosConfigurations.serpantinum = mkDesktop "serpantinum";
    nixosConfigurations.pleamar = mkDesktop "pleamar";
    nixosConfigurations.niri = mkDesktop "niri";
    nixosConfigurations.hyprland = mkDesktop "hyprland";
    nixosConfigurations.cosmic = mkDesktop "cosmic";
  };
}
