# Migration contracts for this machine, separate from reusable category defaults.
{ pkgs, configuration }:
let
  lib = pkgs.lib;
  c = configuration.config;
  h = c.home-manager.users.${c.geko.usuario.nome};
  off =
    (configuration.extendModules {
      modules = [
        ({ lib, ... }: {
          software.gaming.enable = lib.mkForce false;
          software.development.enable = lib.mkForce false;
        })
      ];
    }).config;
  offHome = off.home-manager.users.${off.geko.usuario.nome};
  paths = packages: map (p: p.outPath) packages;
  userPackages = paths h.home.packages;
  expected = with pkgs; [
    brave-origin
    obsidian
    agent-browser
    solaar
    browsers
    fastfetch
    fetch
    comma
    rmatrix
    nix-index
    ripgrep
    ffmpeg
    mcp-nixos
    gh
    nodejs
    python3
    uv
    gcc
    gnumake
    pkg-config
    cmake
    ninja
    antigravity-ide
    antigravity-cli
    codex
    code-cursor
    claude-code
    netbeans
    heroic
    hydralauncher
    prismlauncher
    lunar-client
    mcpelauncher-ui-qt
    mangohud
    dualsensectl
    docker-compose
    lazydocker
    ctop
  ];
  checks = {
    personal-packages = lib.all (p: builtins.elem p.outPath userPackages) expected;
    gaming =
      c.programs.steam.enable
      && c.programs.gamemode.enable
      && c.programs.gamescope.enable
      && c.programs.steam.gamescopeSession.enable
      && c.hardware.xone.enable
      && c.hardware.xpadneo.enable
      && c.programs.steam.remotePlay.openFirewall
      && c.programs.steam.dedicatedServer.openFirewall
      && builtins.length c.programs.steam.extraCompatPackages == 3;
    docker =
      c.virtualisation.docker.enable
      && c.virtualisation.docker.autoPrune.enable
      && c.virtualisation.docker.autoPrune.flags == [ "--all" ]
      && c.virtualisation.docker.daemon.settings."live-restore"
      && builtins.elem "docker" c.users.users.${c.geko.usuario.nome}.extraGroups;
    java = c.programs.java.enable && c.programs.java.package.outPath == pkgs.jdk21.outPath;
    personal-configs =
      h.xdg.configFile ? astronvim
      && h.home.file ? ".claude/skills/arena"
      && h.home.file ? ".claude/skills/pstack-pi"
      && c.environment.variables.NVIM_APPNAME == "astronvim";
    personal-configs-gated =
      !(offHome.xdg.configFile ? astronvim)
      && !(offHome.home.file ? ".claude/skills/arena")
      && !(off.environment.variables ? NVIM_APPNAME)
      && !off.programs.java.enable
      && !off.virtualisation.docker.enable
      && !off.programs.steam.enable;
    desktop-independent =
      lib.all (p: builtins.elem p.outPath (paths off.environment.systemPackages)) [
        pkgs.ddcutil
        pkgs.ddcui
        pkgs.gnome-keyring
      ]
      && off.hardware.graphics.enable
      && off.services.gnome.gnome-keyring.enable
      && offHome.programs.fish.enable;
    categories = !c.software.office.enable && !c.software.studio.enable;
    flatpak =
      c.services.flatpak.enable
      && !c.services.flatpak.uninstallUnmanaged
      && builtins.length c.services.flatpak.packages == 1;
  };
  failed = builtins.attrNames (lib.filterAttrs (_: value: !value) checks);
in
assert lib.assertMsg (
  failed == [ ]
) "Personal software checks failed: ${lib.concatStringsSep ", " failed}";
pkgs.runCommand "software-personal-evaluation" { } ''
  mkdir -p "$out"
  echo '${builtins.toJSON checks}' > "$out/checks.json"
''
