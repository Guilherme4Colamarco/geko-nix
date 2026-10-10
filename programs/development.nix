{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.software.development;
  selected = lib.unique cfg.apps;
  has = name: builtins.elem name selected;
  catalog = {
    neovim = [ ];
    gh = [ pkgs.gh ];
    nodejs = [ pkgs.nodejs ];
    python = [
      pkgs.python3
      pkgs.uv
    ];
    build-tools = with pkgs; [
      gcc
      gnumake
      cmake
      ninja
      pkg-config
    ];
    nix-tools = with pkgs; [
      nixd
      nixfmt
      shellcheck
      shfmt
    ];
    direnv = [ ];
    vscodium = [ pkgs.vscodium ];
    cursor = [ pkgs.code-cursor ];
    antigravity-ide = [ pkgs.antigravity-ide ];
    antigravity-cli = [ pkgs.antigravity-cli ];
    codex = [ pkgs.codex ];
    claude-code = [ pkgs.claude-code ];
    jdk21 = [ ];
    netbeans = [ pkgs.netbeans ];
    sqldeveloper = [ (pkgs.callPackage ../pkgs/sqldeveloper.nix { }) ];
    dbeaver = [ pkgs.dbeaver-bin ];
    go = [ pkgs.go ];
    rust = [
      pkgs.rustc
      pkgs.cargo
    ];
  };
in
{
  imports = [ ../modules/services/docker.nix ];
  options.software.development =
    (import ./category.nix { inherit lib; } {
      name = "development";
      inherit catalog;
      defaults = [
        "neovim"
        "gh"
        "nodejs"
        "python"
        "build-tools"
        "nix-tools"
        "direnv"
      ];
    })
    // {
      docker.enable = lib.mkEnableOption "Docker Engine, Compose, lazydocker, ctop and Docker group access";
    };
  config = lib.mkIf cfg.enable {
    programs.java = lib.mkIf (has "jdk21") {
      enable = true;
      package = pkgs.jdk21;
    };
    home-manager.users.${config.geko.usuario.nome} = {
      home.packages = lib.unique (lib.concatMap (name: catalog.${name}) selected ++ cfg.extraPackages);
      programs.neovim = lib.mkIf (has "neovim") {
        enable = true;
        defaultEditor = true;
      };
      programs.direnv = lib.mkIf (has "direnv") {
        enable = true;
        nix-direnv.enable = true;
        enableFishIntegration = true;
      };
    };
  };
}
