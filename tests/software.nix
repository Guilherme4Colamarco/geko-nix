# Evaluation-only regressions: no VM, downloads or category applications are built.
{ inputs, pkgs }:
let
  lib = inputs.nixpkgs.lib;
  categories = [
    "gaming"
    "office"
    "development"
    "studio"
  ];
  mkSystem =
    software:
    inputs.nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-flatpak.nixosModules.nix-flatpak
        ../modules/core/usuario.nix
        ../programs
        {
          disabledModules = [ ../programs/user.nix ];
          nixpkgs.config.allowUnfree = true;
          system.stateVersion = "26.05";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.geko = {
            home.username = "geko";
            home.homeDirectory = "/home/geko";
            home.stateVersion = "26.05";
          };
          users.users.geko.isNormalUser = true;
          inherit software;
        }
      ];
    };
  mk = software: (mkSystem software).config;
  hm = c: c.home-manager.users.geko;
  paths = c: map (p: p.drvPath) (hm c).home.packages;
  enabled = name: mk { ${name}.enable = true; };
  off = mk { };
  all = mk (
    lib.genAttrs categories (_: {
      enable = true;
    })
  );
  empty = mk (
    lib.genAttrs categories (_: {
      enable = true;
      apps = [ ];
    })
  );
  duplicate = mk {
    gaming = {
      enable = true;
      apps = [
        "heroic"
        "heroic"
      ];
    };
  };
  single = mk {
    gaming = {
      enable = true;
      apps = [ "heroic" ];
    };
  };
  flats = mk {
    gaming = {
      enable = true;
      apps = [
        "sober"
        "roblox"
        "modrinth"
        "sober"
      ];
    };
    flatpak.packages = [
      "org.vinegarhq.Sober"
      "org.vinegarhq.Sober"
    ];
  };
  integrations = mk {
    gaming = {
      enable = true;
      apps = [ "steam" ];
      controllers.enable = true;
      optimizations.enable = true;
      steam.remotePlay.enable = true;
      steam.dedicatedServer.enable = true;
      proton = [
        "ge"
        "dw"
        "cachyos"
        "ge"
      ];
    };
    development = {
      enable = true;
      apps = [ ];
      docker.enable = true;
    };
  };
  disabledIntegrations = mk {
    gaming = {
      controllers.enable = true;
      optimizations.enable = true;
      steam.remotePlay.enable = true;
      steam.dedicatedServer.enable = true;
    };
    development.docker.enable = true;
  };
  extras = mk {
    office = {
      enable = true;
      apps = [ ];
      extraPackages = [ pkgs.hello ];
    };
  };
  hiddenExtras = mk { office.extraPackages = [ (throw "Disabled extraPackages were evaluated") ]; };
  raw = mk {
    user.packages = [
      pkgs.neovim
      pkgs.obs-studio
    ];
  };
  noSteam = mk {
    gaming = {
      enable = true;
      apps = [ ];
      proton = [ "dw" ];
      steam.remotePlay.enable = true;
    };
  };
  invalid =
    name:
    builtins.tryEval (
      builtins.deepSeq (mk { ${name}.apps = [ "invalid-app" ]; }).software.${name}.apps true
    );
  # Resolve every selectable app, including optional entries, without building it.
  catalog = lib.genAttrs categories (
    name:
    let
      names =
        (mkSystem { }).options.software.${name}.apps.type.nestedTypes.elemType.functor.payload.values;
    in
    paths (mk {
      ${name} = {
        enable = true;
        apps = names;
      };
    })
  );
  checks = {
    defaults-off = lib.all (name: !off.software.${name}.enable) categories;
    off-services =
      !off.programs.steam.enable
      && !off.virtualisation.docker.enable
      && !off.services.flatpak.enable
      && !off.hardware.xone.enable
      && !off.hardware.xpadneo.enable;
    empty-apps = paths empty == paths off;
    empty-services =
      !empty.programs.steam.enable
      && !(hm empty).programs.neovim.enable
      && !(hm empty).programs.obs-studio.enable
      && !empty.programs.java.enable;
    duplicates = paths duplicate == paths single;
    extra-only = builtins.elem pkgs.hello.drvPath (paths extras);
    disabled-extra-lazy = paths hiddenExtras == paths off;
    raw-packages-only = !(hm raw).programs.neovim.enable && !(hm raw).programs.obs-studio.enable;
    flatpak-auto =
      flats.services.flatpak.enable
      && builtins.length flats.services.flatpak.packages == 2
      && !flats.services.flatpak.uninstallUnmanaged
      && !flats.services.flatpak.uninstallUnused;
    gaming-defaults =
      (enabled "gaming").programs.steam.enable
      && !(enabled "gaming").programs.steam.remotePlay.openFirewall
      && !(enabled "gaming").programs.steam.dedicatedServer.openFirewall
      && !(enabled "gaming").hardware.xone.enable
      && !(enabled "gaming").programs.gamemode.enable
      && builtins.length (enabled "gaming").programs.steam.extraCompatPackages == 1;
    development-defaults =
      (hm (enabled "development")).programs.neovim.enable
      && (hm (enabled "development")).programs.direnv.nix-direnv.enable
      && (hm (enabled "development")).programs.direnv.enableFishIntegration
      && !(enabled "development").virtualisation.docker.enable;
    studio-obs =
      (hm (enabled "studio")).programs.obs-studio.enable
      && builtins.length (hm (enabled "studio")).programs.obs-studio.plugins == 1;
    integrations-on =
      integrations.hardware.xone.enable
      && integrations.hardware.xpadneo.enable
      && integrations.programs.gamemode.enable
      && integrations.programs.gamescope.enable
      && integrations.programs.steam.gamescopeSession.enable
      && integrations.programs.steam.remotePlay.openFirewall
      && integrations.programs.steam.dedicatedServer.openFirewall
      && integrations.virtualisation.docker.enable
      && builtins.elem "docker" integrations.users.users.geko.extraGroups
      && builtins.length integrations.programs.steam.extraCompatPackages == 3;
    integrations-gated =
      !disabledIntegrations.hardware.xone.enable
      && !disabledIntegrations.hardware.xpadneo.enable
      && !disabledIntegrations.programs.gamemode.enable
      && !disabledIntegrations.virtualisation.docker.enable
      && !builtins.elem "docker" disabledIntegrations.users.users.geko.extraGroups
      && !noSteam.programs.steam.remotePlay.openFirewall
      && noSteam.programs.steam.extraCompatPackages == [ ];
    invalid-apps = lib.all (name: !(invalid name).success) categories;
    invalid-disabled-assertion =
      !(builtins.tryEval (
        builtins.deepSeq (map (a: a.assertion) (mk { office.apps = [ "invalid-app" ]; }).assertions) true
      )).success;
    invalid-proton =
      !(builtins.tryEval (
        builtins.deepSeq (mk { gaming.proton = [ "invalid" ]; }).software.gaming.proton true
      )).success;
    all-packages = builtins.deepSeq (paths all) true;
    each-category = lib.all (name: builtins.deepSeq (paths (enabled name)) true) categories;
    catalog-packages = builtins.deepSeq catalog true;
  };
  failed = builtins.attrNames (lib.filterAttrs (_: value: !value) checks);
in
assert lib.assertMsg (
  failed == [ ]
) "Software evaluation checks failed: ${lib.concatStringsSep ", " failed}";
pkgs.runCommand "software-evaluation" { } ''
  mkdir -p "$out"
  echo '${builtins.toJSON checks}' > "$out/checks.json"
''
