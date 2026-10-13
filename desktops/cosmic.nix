# Perfil COSMIC (alvo `cosmic`): desktop tradicional, sem Honey e sem Hyprland.
# O login é o cosmic-greeter (greetd). O SDDM da base fica desligado só aqui.
{ lib, pkgs, ... }: {
  imports = [ ./_comum.nix ];

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.displayManager.defaultSession = "cosmic";
  services.displayManager.sddm.enable = lib.mkForce false;

  # Repositórios extras, ativos só neste perfil. O remoto COSMIC (System76)
  # alimenta a COSMIC Store; o flathub precisa ser repetido porque a lista
  # declarada aqui substitui o padrão do nix-flatpak.
  services.flatpak = {
    enable = lib.mkForce true;
    remotes = [
      { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
      { name = "cosmic"; location = "https://apt.pop-os.org/cosmic/cosmic.flatpakrepo"; }
    ];
  };

  # Ajustes extras: Tweaks (temas, layouts, painel) e applets da comunidade.
  environment.systemPackages = with pkgs; [
    cosmic-ext-tweaks
    cosmic-ext-ctl
    cosmic-ext-applet-caffeine
    cosmic-ext-applet-minimon
    cosmic-ext-applet-external-monitor-brightness
    cosmic-ext-applet-privacy-indicator
    cosmic-ext-applet-weather
    cosmic-ext-calculator
    tasks
    forecast
    examine
    quick-webapps
  ];
}
