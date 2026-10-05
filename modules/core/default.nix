{ pkgs, desktopProfile ? "nixos", ... }: {
  programs.fish.enable = true;
  users.users.geko.shell = pkgs.fish;
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    ntfs3g exfatprogs dosfstools rsync gparted git micro zoxide tree
    bat eza starship fzf atuin direnv yazi age trashy btop fd wget curl jq socat
  ];
  boot.loader.systemd-boot.configurationLimit = 10;
  nix.settings.auto-optimise-store = true;
  system.autoUpgrade = {
    enable = true;
    flake = "/home/geko/Documentos/geko-nix#${desktopProfile}";
    operation = "boot";
    allowReboot = false;
    dates = "04:40";
    randomizedDelaySec = "20min";
    persistent = true;
    upgrade = false;
    flags = [
      "--update-input" "nixpkgs"
      "--update-input" "nixpkgs-unstable"
      "--update-input" "home-manager"
      "--update-input" "claude-desktop-app"
    ];
  };
  programs.nh = {
    enable = true;
    flake = "/home/geko/Documentos/geko-nix";
    clean = { enable = true; extraArgs = "--keep 10 --keep-since 14d"; };
  };
  xdg.mime.defaultApplications = {
    "text/html" = "brave-origin.desktop";
    "x-scheme-handler/http" = "brave-origin.desktop";
    "x-scheme-handler/https" = "brave-origin.desktop";
  };
}
