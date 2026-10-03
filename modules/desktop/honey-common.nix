{ pkgs, ... }: {
  services.upower.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;
  security.pam.services.swaylock = {};
  hardware.i2c.enable = true;
  users.users.geko.extraGroups = [ "i2c" ];
  environment.systemPackages = [ pkgs.ddcutil pkgs.adwaita-icon-theme ];
}
