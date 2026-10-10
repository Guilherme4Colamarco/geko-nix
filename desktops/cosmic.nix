# Perfil COSMIC (alvo `cosmic`): desktop tradicional, sem Honey e sem Hyprland.
# O login é o cosmic-greeter (greetd). O SDDM da base fica desligado só aqui.
{ lib, ... }: {
  imports = [ ./_comum.nix ];

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.displayManager.defaultSession = "cosmic";
  services.displayManager.sddm.enable = lib.mkForce false;
}
