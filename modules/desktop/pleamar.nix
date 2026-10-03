{ pkgs, inputs, ... }: {
  imports = [ ./honey-common.nix ];
  programs.pleamar-wm = {
    enable = true;
    withMarea = false;
    package = import ../../pkgs/pleamar-wm.nix { upstream = inputs.pleamar-wm.packages.${pkgs.stdenv.hostPlatform.system}.pleamar-wm; };
  };
  services.displayManager.defaultSession = "pleamar-wm";
  home-manager.users.geko.imports = [ ../../home/desktop/pleamar.nix ];
}
