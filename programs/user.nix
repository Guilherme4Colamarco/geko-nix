# Personal choices. Category defaults are intended for new users, not this machine.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  dev = config.software.development;
  hasDev = name: dev.enable && builtins.elem name dev.apps;
in
{
  software = {
    user.packages =
      with pkgs;
      [
        brave-origin
        obsidian
        agent-browser
        solaar
        browsers
        vial
        fastfetch
        fetch
        comma
        rmatrix
        nix-index
        ripgrep
        ffmpeg
        mcp-nixos
        baobab
      ]
      ++ [
        inputs.claude-desktop-app.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.chatgpt-desktop-app.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    flatpak.packages = [ "com.stremio.Stremio" ];
    gaming = {
      enable = true;
      apps = [
        "steam"
        "heroic"
        "hydra"
        "prism"
        "lunar"
        "bedrock"
        "mangohud"
        "dualsensectl"
        "protontricks" # roda o ReSkateLauncher no prefixo do skate.
      ];
      controllers.enable = true;
      optimizations.enable = true;
      steam.remotePlay.enable = true;
      steam.dedicatedServer.enable = true;
      proton = [
        "ge"
        "dw"
        "cachyos"
      ];
    };
    office.enable = false;
    development = {
      enable = true;
      apps = [
        "neovim"
        "gh"
        "nodejs"
        "python"
        "build-tools"
        "direnv"
        "antigravity-ide"
        "antigravity-cli"
        "codex"
        "cursor"
        "claude-code"
        "jdk21"
        "netbeans"
        "sqldeveloper"
      ];
      docker.enable = true;
    };
    studio.enable = false;
  };

  # Personal Claude Desktop Cowork integration; no VM is started automatically.
  users.users.${config.geko.usuario.nome}.extraGroups = [ "kvm" ];
  boot.kernelModules = [ "vhost_vsock" ];

  # Regra udev oficial do Vial: teclados com firmware Vial acessíveis sem sudo.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

  # Personal editor and skills remain conditional on their category selections.
  environment.variables = lib.mkIf (hasDev "neovim") {
    NVIM_APPNAME = "astronvim";
    VISUAL = "nvim";
  };
  home-manager.users.${config.geko.usuario.nome} = {
    imports = [
      ../home/astronvim.nix
      ../home/claude-code.nix
      ../home/game-modding.nix
      ../home/netbeans.nix
    ];
  };
}
