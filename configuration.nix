# Configuração base da máquina: boot, rede, idioma (pt-BR), teclado, som,
# impressão e o usuário. O que é de desktop, programas ou hardware específico
# fica em desktops/, programs/ e modules/. Veja o README.
{ config, ... }:

{
  imports = [
    # Gerado pelo instalador do NixOS (discos, kernel). Não edite à mão.
    ./hardware-configuration.nix
  ];

  # Carregador de boot EFI do systemd.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Habilita o comando `nix` novo e os flakes.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Sao_Paulo";

  # Idioma e formatos regionais.
  i18n.defaultLocale = "pt_BR.UTF-8";

  i18n.extraLocaleSettings = {
    LANGUAGE = "pt_BR:pt";
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_COLLATE = "pt_BR.UTF-8";
    LC_CTYPE = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MESSAGES = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Servidor gráfico X11 (também necessário ao SDDM e ao driver NVIDIA).
  services.xserver.enable = true;

  # Permite controlar o brilho do monitor externo por DDC/CI (ddcutil).
  hardware.i2c.enable = true;

  # Dá à sessão ativa acesso ao receptor Logitech (Solaar).
  hardware.logitech.wireless.enable = true;

  # Bluetooth (ex.: controle de PS3 sem fio). Para parear o DualShock 3,
  # grave antes o endereço do adaptador no controle com o `sixpair` (via USB).
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.displayManager.sddm.enable = true;

  # Teclado no X11 (ABNT2).
  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  # Teclado no console.
  console.keyMap = "br-abnt2";

  # Impressão (CUPS).
  services.printing.enable = true;

  # Som com PipeWire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Usuário principal. Defina a senha com `passwd` depois da instalação.
  users.users.${config.geko.usuario.nome} = {
    isNormalUser = true;
    description = config.geko.usuario.nome;
    extraGroups = [ "networkmanager" "wheel" "i2c" ];
  };

  # Permite programas não livres (NVIDIA, Steam, etc.).
  nixpkgs.config.allowUnfree = true;

  # Versão do NixOS em que esta máquina foi instalada. Serve só para manter
  # compatibilidade com dados antigos (bancos de dados, por exemplo). NÃO mude
  # ao atualizar o sistema: isso não atualiza nada e pode quebrar dados.
  # Mais em `man configuration.nix` ou no manual do NixOS (opção stateVersion).
  system.stateVersion = "26.05";
}
