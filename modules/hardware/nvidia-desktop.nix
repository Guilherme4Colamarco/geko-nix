# Placa NVIDIA dedicada (RTX 20/30/40/50): driver aberto, KMS e aceleração de vídeo.
# Tudo com mkDefault, então pode ser sobrescrito em outro módulo.
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.ddcutil pkgs.ddcui ];

  # --- GPU NVIDIA dedicada ---
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting é obrigatório para Wayland / KMS
    modesetting.enable = lib.mkDefault true;

    # Gerenciamento de energia para suspender
    powerManagement.enable = lib.mkDefault true;
    powerManagement.finegrained = lib.mkDefault false;

    # Módulos de kernel abertos (padrão de Turing, Ada e Blackwell / RTX 50)
    open = lib.mkDefault true;

    # Painel de controle da NVIDIA
    nvidiaSettings = lib.mkDefault true;

    # Driver estável
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Aceleração de vídeo por hardware
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      nvidia-vaapi-driver
    ];
  };

  # Variáveis de ambiente para Wayland e compositores
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = lib.mkDefault "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = lib.mkDefault "nvidia";
    NVD_BACKEND = lib.mkDefault "direct";
    ELECTRON_OZONE_PLATFORM_HINT = lib.mkDefault "auto";
  };

  # KMS cedo no boot (initrd) para compositores Wayland
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
}
