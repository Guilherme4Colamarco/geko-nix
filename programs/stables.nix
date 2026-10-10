# Programas do canal estável (nixos-26.05): editor, monitor/brilho, navegadores e Logitech.
{ pkgs, ... }:

{
  programs.firefox.enable = false;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # O AstroNvim usa a própria config gerenciada pelo Nix (home/default.nix).
  environment.variables.NVIM_APPNAME = "astronvim";
  environment.variables.VISUAL = "nvim";

  environment.systemPackages = with pkgs; [
    # Brilho do monitor (DDC/CI): CLI e app gráfico.
    ddcutil
    ddcui
    # Navegador para agentes; usa o carregador dinâmico do NixOS.
    agent-browser
    # Chaveiro do GNOME, usado pelos apps de sessão.
    gnome-keyring
    solaar
    # Parear controle de PS3 (DualShock 3): grava o endereço do adaptador via USB.
    sixpair
    bluetuith
    browsers
  ];
}
