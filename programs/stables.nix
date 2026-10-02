{ pkgs, ... }:

{
  programs.firefox.enable = false;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Ryoku manages ~/.config/nvim, so AstroVim uses its own Nix-managed config.
  environment.variables.NVIM_APPNAME = "astronvim";
  environment.variables.VISUAL = "nvim";

  # Monitor brightness controls (DDC/CI CLI and graphical app).
  environment.systemPackages = with pkgs; [
    ddcutil
    ddcui
    # Nix-packaged agent-browser uses the NixOS dynamic loader, unlike Hermes's generic Linux bundle.
    agent-browser
    # Keep Ryoku/Hyprland's GNOME file-manager and keyring dependencies
    # available even when Pantheon is disabled.
    nautilus
    gnome-keyring
    pkgs.solaar
    pkgs.browsers
  ];
}
