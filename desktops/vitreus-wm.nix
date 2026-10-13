# Perfil Vitreus no pleamar-wm (alvo `vitreus-wm`): compositor pleamar-wm (sem Marea) + shell Vitreus.
# Base comum em _vitreus.nix. Parte 1 = sistema (NixOS); parte 2 = usuário (Home Manager).
#
# Substitui o pleamar-wm/install-session.sh do Vitreus: a sessão entra no SDDM pelo módulo NixOS
# do pleamar-wm. O que não funciona fora do Hyprland (upstream): páginas Hyprland e Display do
# Settings, lista de janelas do overview, Modo Noturno.
{ config, lib, pkgs, inputs, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.geko.desktop;
in {
  imports = [ inputs.pleamar-wm-vitreus.nixosModules.default ./_vitreus.nix ];
  programs.pleamar-wm = {
    enable = true;
    withMarea = false;
    # Mesmo patch de framebuffer do perfil pleamar (aplica no 0.3.13).
    package = import ../pkgs/pleamar-wm { upstream = inputs.pleamar-wm-vitreus.packages.${system}.pleamar-wm; };
  };
  services.displayManager.defaultSession = "pleamar-wm";
  # A sessão exporta XDG_CURRENT_DESKTOP=pleamar. Sem este mapa o portal não
  # escolhe implementação e o diálogo de arquivo não abre (igual ao perfil pleamar).
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-gnome ];
  xdg.portal.config.pleamar = {
    default = [ "gnome" "gtk" ];
    "org.freedesktop.impl.portal.Access" = [ "gtk" ];
    "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };

  # ---------- Parte 2: usuário (Home Manager) ----------
  home-manager.users.${config.geko.usuario.nome} = { config, lib, pkgs, ... }: {
    # O Vitreus pergunta ao hyprctl pelos monitores e pela janela ativa; aqui quem responde é o pleamar-wm.
    home.packages = [
      (pkgs.writeShellScriptBin "hyprctl" ''exec pleamar-wm hyprctl "$@"'')
    ];

    xdg.configFile = {
      # As teclas do Vitreus para o pleamar-wm (defaults + launcher, Settings, lock, Capture, mídia),
      # mais terminal e gerenciador de arquivos do geko.desktop. `bind` repetido troca o anterior.
      "pleamar/keys.conf".text = builtins.readFile "${inputs.vitreus}/pleamar-wm/keys.conf" + ''

        # geko-nix
        bind Super+Return       launch ${lib.getExe cfg.terminal}
        bind Super+e            launch ${lib.getExe cfg.fileManager}
      '';
      # A cena de janelas do Vitreus importa ../../wm-palette.plm: aponta para a cópia gravável do shell.
      "pleamar/wm".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/pleamar/shells/vitreus/pleamar-wm/wm";
      # O Settings do Vitreus edita pointer/touchpad/idle aqui com `sed -i`. force: o switch seguinte
      # sobrescreve sem backup (um .before-geko-nix bloquearia a ativação).
      "pleamar/session.conf" = {
        force = true;
        text = ''
          monitor "" preferred scale 1
          monitor DP-1 1920x1080@165.003 at 0,0 scale 1.25
          keyboard layout br repeat 25 delay 400
          pointer accel flat speed 0
          touchpad natural on tap on dwt on
          idle off-after 420
          agent on
          window app=pavucontrol float size 820x560
          window title="Picture in Picture" float
        '';
      };
      # Os daemons que o install.sh acrescenta ao autostart (no Hyprland quem sobe é o hypr_vitreus.lua).
      "pleamar/autostart".text = lib.mkAfter ''
        # >>> vitreus (session)
        pgrep -x awww-daemon > /dev/null || awww-daemon
        sleep 1; awww restore
        pgrep -x hypridle > /dev/null || hypridle
        pgrep -x wl-paste > /dev/null || wl-paste --watch cliphist store
        # <<< vitreus
      '';
    };
  };
}
