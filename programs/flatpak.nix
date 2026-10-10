{ config, lib, ... }:
let
  cfg = config.software.flatpak;
  packages = lib.unique (cfg.packages ++ cfg.categoryPackages);
in
{
  options.software.flatpak = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Personal Flatpak application IDs from Flathub (system installation).";
    };
    categoryPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      internal = true;
      description = "Flatpak application IDs contributed by enabled categories.";
    };
  };
  config.services.flatpak = {
    enable = packages != [ ];
    inherit packages;
    # Keep manually installed applications and remotes, including on rollback.
    uninstallUnmanaged = false;
    uninstallUnused = false;
  };
}
