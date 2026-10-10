{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.software.gaming;
  selected = lib.unique cfg.apps;
  has = name: builtins.elem name selected;
  flatpakWrapper =
    name: id:
    pkgs.writeShellScriptBin name ''
      exec ${pkgs.flatpak}/bin/flatpak run ${id} "$@"
    '';
  catalog = {
    steam = [ ];
    heroic = [ pkgs.heroic ];
    hydra = [ pkgs.hydralauncher ];
    lutris = [ pkgs.lutris ];
    bottles = [ pkgs.bottles ];
    itch = [ pkgs.itch ];
    sober = [ (flatpakWrapper "sober" "org.vinegarhq.Sober") ];
    roblox = catalog.sober;
    prism = [ pkgs.prismlauncher ];
    lunar = [ pkgs.lunar-client ];
    bedrock = [ pkgs.mcpelauncher-ui-qt ];
    modrinth = [ (flatpakWrapper "modrinth" "com.modrinth.ModrinthApp") ];
    atlauncher = [ pkgs.atlauncher ];
    gdlauncher = [ pkgs.gdlauncher-carbon ];
    badlion = [ pkgs.badlion-client ];
    pcsx2 = [ pkgs.pcsx2 ];
    rpcs3 = [ pkgs.rpcs3 ];
    dolphin = [ pkgs.dolphin-emu ];
    retroarch = [ pkgs.retroarch ];
    ppsspp = [ pkgs.ppsspp ];
    mangohud = [ pkgs.mangohud ];
    dualsensectl = [ pkgs.dualsensectl ];
    protonup-qt = [ pkgs.protonup-qt ];
    protontricks = [ pkgs.protontricks ];
    goverlay = [ pkgs.goverlay ];
  };
  protons = import ./proton.nix { inherit pkgs; };
in
{
  options.software.gaming =
    (import ./category.nix { inherit lib; } {
      name = "gaming";
      inherit catalog;
      defaults = [
        "steam"
        "heroic"
        "prism"
        "mangohud"
      ];
    })
    // {
      controllers.enable = lib.mkEnableOption "Xbox drivers and DualSense udev rules";
      optimizations.enable = lib.mkEnableOption "GameMode, Gamescope and the Steam Gamescope session";
      steam.remotePlay.enable = lib.mkEnableOption "Steam Remote Play firewall ports";
      steam.dedicatedServer.enable = lib.mkEnableOption "Steam dedicated server firewall ports";
      proton = lib.mkOption {
        type = lib.types.listOf (lib.types.enum (builtins.attrNames protons));
        default = [ "ge" ];
        description = "Steam compatibility tools: GE, pinned DW-Proton or pinned Proton-CachyOS.";
      };
    };
  config = lib.mkIf cfg.enable {
    home-manager.users.${config.geko.usuario.nome}.home.packages = lib.unique (
      lib.concatMap (name: catalog.${name}) selected ++ cfg.extraPackages
    );
    programs.gamemode.enable = cfg.optimizations.enable;
    programs.gamescope.enable = cfg.optimizations.enable;
    programs.steam = lib.mkIf (has "steam") {
      enable = true;
      extraCompatPackages = map (name: protons.${name}) (lib.unique cfg.proton);
      remotePlay.openFirewall = cfg.steam.remotePlay.enable;
      dedicatedServer.openFirewall = cfg.steam.dedicatedServer.enable;
      gamescopeSession.enable = cfg.optimizations.enable;
    };
    hardware.xone.enable = cfg.controllers.enable;
    hardware.xpadneo.enable = cfg.controllers.enable;
    services.udev.packages = lib.optionals cfg.controllers.enable [ pkgs.dualsensectl ];
    software.flatpak.categoryPackages =
      lib.optional (has "sober" || has "roblox") "org.vinegarhq.Sober"
      ++ lib.optional (has "modrinth") "com.modrinth.ModrinthApp";
  };
}
