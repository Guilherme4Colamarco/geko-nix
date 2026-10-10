# Shared option schema. Enum keys are inspected without evaluating package values.
{ lib }:
{
  name,
  catalog,
  defaults,
}:
{
  enable = lib.mkEnableOption "${name} software and selected integrations";
  apps = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (builtins.attrNames catalog));
    default = defaults;
    description = "Applications to install. An explicit list replaces the defaults; [] installs none.";
  };
  extraPackages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Additional user packages, installed only while this category is enabled.";
  };
}
