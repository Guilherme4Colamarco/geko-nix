{ config, inputs, unstablePkgs, ... }:

{
  environment.systemPackages = with unstablePkgs; [
    antigravity-ide
    antigravity-cli
    brave-origin
    codex
    code-cursor
    claude-code
    fastfetch
    fetch
    comma
    obsidian
    rmatrix
    nix-index

  ] ++ [
    inputs.claude-desktop-app.packages.${unstablePkgs.stdenv.hostPlatform.system}.default
  ];

  # Claude Desktop's local Cowork VM needs these devices; no VM autostarts.
  users.users.${config.geko.usuario.nome}.extraGroups = [ "kvm" ];
  boot.kernelModules = [ "vhost_vsock" ];
}
