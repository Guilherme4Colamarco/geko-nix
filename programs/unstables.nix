{ inputs, unstablePkgs, ... }:

{
  environment.systemPackages = with unstablePkgs; [
    antigravity-ide
    antigravity-cli
    brave-origin
    codex
    code-cursor
    fastfetch
    fetch
    comma
    obsidian
    rmatrix
    nix-index

  ] ++ [ inputs.chatgpt-desktop-app.packages.${unstablePkgs.stdenv.hostPlatform.system}.default ];
}
