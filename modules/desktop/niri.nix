{ unstablePkgs, ... }: {
  imports = [ ./honey-common.nix ];
  programs.niri = { enable = true; package = unstablePkgs.niri; };
  environment.systemPackages = [ unstablePkgs.xwayland-satellite ];
  services.displayManager.defaultSession = "niri";
  home-manager.users.geko.imports = [ ../../home/desktop/niri.nix ];
}
