# Perfil Pleamar: gerenciador de janelas pleamar-wm (sem Marea) + shell Honey.
# Parte 1 = sistema (NixOS); parte 2 = usuário (Home Manager: atalhos e sessão).
{ config, pkgs, inputs, ... }: {
  imports = [ inputs.pleamar-wm.nixosModules.default ./_comum-honey.nix ];
  programs.pleamar-wm = {
    enable = true;
    withMarea = false;
    package = import ../pkgs/pleamar-wm.nix { upstream = inputs.pleamar-wm.packages.${pkgs.stdenv.hostPlatform.system}.pleamar-wm; };
  };
  services.displayManager.defaultSession = "pleamar-wm";
  # A sessão exporta XDG_CURRENT_DESKTOP=pleamar. Sem este mapa o portal não
  # escolhe implementação e o diálogo de arquivo não abre.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-gnome ];
  xdg.portal.config.pleamar = {
    default = [ "gnome" "gtk" ];
    "org.freedesktop.impl.portal.Access" = [ "gtk" ];
    "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };

  # ---------- Parte 2: usuário (Home Manager) ----------
  home-manager.users.${config.geko.usuario.nome} = { config, lib, pkgs, inputs, ... }:
  let
    honey = config.programs.honeyShell.package.override { settings = config.programs.honeyShell.settings; };
    ctl = "${honey}/bin/honeyctl";
    common = [
      "bind Super+Return launch ${pkgs.kitty}/bin/kitty"
      "bind Super+E launch ${pkgs.nautilus}/bin/nautilus"
      "bind Super+space launch ${ctl} toggle launcher"
      "bind Super+d launch ${ctl} toggle launcher"
      "bind Super+v launch ${ctl} toggle clipboard"
      "bind Super+comma launch ${ctl} toggle settings"
      "bind Super+l launch ${ctl} lock"
      "bind Super+Shift+e launch ${ctl} toggle power"
      "bind Super+Shift+w launch ${ctl} toggle wallpapers"
      "bind Super+Shift+n launch ${ctl} toggle notifications"
      "bind Print launch ${ctl} screenshot region"
      "bind Shift+Print launch ${ctl} screenshot screen"
      "bind Super+q close" "bind Super+f fullscreen" "bind Super+Shift+f toggle_float"
      "bind Super+Ctrl+f toggle_free" "bind Super+Tab overview"
      "bind Super+m minimize" "bind Super+Shift+m restore_last"
      "bind Super+Left focus_previous" "bind Super+Right focus_next"
      "bind Super+Up focus_previous" "bind Super+Down focus_next"
      "bind Super+Shift+Left move_left" "bind Super+Shift+Right move_right"
      "bind Super+Shift+Up move_up" "bind Super+Shift+Down move_down"
      "bind Super+minus narrower" "bind Super+plus wider"
      "bind Super+Ctrl+Up workspace_previous" "bind Super+Ctrl+Down workspace_next"
      "gesture swipe4_left focus_previous" "gesture swipe4_right focus_next"
    ];
    media = import ./media-keys.nix;
    scene = pkgs.runCommand "honey-wm-scene" { nativeBuildInputs = [ inputs.pleamar-wm.inputs.pleamar.packages.${pkgs.stdenv.hostPlatform.system}.pleamar ]; } ''
      mkdir -p $out
      cp ${inputs.pleamar-wm}/examples/session.plm $out/session.plm
      cp -r ${inputs.pleamar-wm}/examples/shaders $out/shaders
      substituteInPlace $out/session.plm \
        --replace-fail '#f5f7f5' '#fff0ca' --replace-fail '#9ed6bd' '#ffdb85' \
        --replace-fail '#ef7a66' '#ffad28' --replace-fail '#e8c26a' '#b97912' \
        --replace-fail '#151616' '#24201b'
      # Remove upstream notifications to the optional Marea shell, keeping WM layout rules.
      sed -i "/launch.*--say marea/d" $out/session.plm
      # O texto do WM (tooltips, badges e dígitos de workspace; não há texto em barra
      # de título) não declara `family:` e cai no
      # sans-serif do fontdb, que não segue fonts.fontconfig.defaultFonts
      # (o fontdb fica com o ÚLTIMO alias sans-serif que lê; hoje 69-unifont.conf,
      # FreeSans, não o 52-nixos-default-fonts.conf). Nomeia Nunito.
      sed -i -E '/^\s*(text|input) [^=]*\{/{/family:/!s/\{ /{ family: "Nunito"; /}' $out/session.plm
      # Nunito é menor que a DejaVu (x-height 0,484 contra 0,547): tooltips ganham 1 px.
      sed -i 's/size: 12; weight: 600; color: ink; measure/size: 13; weight: 700; color: ink; measure/' $out/session.plm
      # Todo elemento `text` precisa ter recebido a família; senão o texto cairia em silêncio no fallback.
      test "$(grep -c 'family: "Nunito"' $out/session.plm)" -ge "$(grep -cE '^[[:space:]]*text ' $out/session.plm)"
      pleamar --check $out/session.plm
    '';
  in {
    imports = [ ../home/honey.nix ];
    programs.honeyShell.enable = true;
    programs.honeyShell.settings.compositor = "pleamar-wm";
    xdg.configFile = {
      "pleamar/keys.conf".text = lib.concatStringsSep "\n" (common
        ++ lib.mapAttrsToList (key: action: "bind ${key} ${lib.optionalString (lib.elem action [ "volume-up" "volume-down" "brightness-up" "brightness-down" ]) "repeat "}locked launch ${ctl} media ${action}") media
        ++ lib.concatMap (i: [ "bind Super+${toString i} workspace ${toString i}" "bind Super+Shift+${toString i} move_to_workspace ${toString i}" ]) (lib.range 1 9)) + "\n";
      "pleamar/session.conf".text = ''
        monitor "" preferred scale 1
        monitor DP-1 1920x1080@165.003 at 0,0 scale 1.25
        keyboard layout br repeat 25 delay 400
        pointer accel flat speed 0
        touchpad natural on tap on dwt on
        window app=pavucontrol float size 820x560
        window title="Picture in Picture" float
      '';
      "pleamar/autostart".text = "${ctl} session\n";
      "pleamar/wm".source = scene;
    };
  };
}
