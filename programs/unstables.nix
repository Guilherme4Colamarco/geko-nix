{ unstablePkgs, ... }:

{
  environment.systemPackages = with unstablePkgs; [
    brave-origin
    codex
    code-cursor
    fastfetch
    fetch
    comma
    obsidian
    rmatrix
    nix-index

  ];
}
