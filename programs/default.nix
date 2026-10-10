{ config, lib, ... }: {
  imports = [
    ./user.nix
    ./flatpak.nix
    ./gaming.nix
    ./office.nix
    ./development.nix
    ./studio.nix
  ];
  options.software.user.packages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Personal packages without category configuration or integrations.";
  };
  config = {
    # Validate names even in disabled categories, without forcing any packages.
    assertions = [
      {
        assertion = builtins.deepSeq (
          map (name: config.software.${name}.apps) [
            "gaming"
            "office"
            "development"
            "studio"
          ]
          ++ [ config.software.gaming.proton ]
        ) true;
        message = "Software selections must use catalog names.";
      }
    ];
    home-manager.users.${config.geko.usuario.nome}.home.packages =
      lib.unique config.software.user.packages;
  };
}
