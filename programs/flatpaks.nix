# Apps Flatpak declarativos (nix-flatpak): hoje só o Stremio.
{ ... }:

{
  services.flatpak = {
    enable = true;
    packages = [
      "com.stremio.Stremio"
    ];
  };
}
