{ ... }:

{
  services.flatpak = {
    enable = true;
    packages = [
      "com.stremio.Stremio"
    ];
  };
}
