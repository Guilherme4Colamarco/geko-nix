# Base dos perfis Vitreus (vitreus = Hyprland, vitreus-wm = pleamar-wm): o que o install.sh
# do Vitreus faz no Arch, em Nix. Importada por desktops/vitreus.nix e desktops/vitreus-wm.nix.
# Parte 1 = sistema (pacotes de sistema, serviços, fontes, PAM); parte 2 = usuário (Home Manager).
#
# O Vitreus precisa morar, gravável, em ~/.config/pleamar/shells/vitreus: ele grava palette.plm e
# wm-palette.plm ali e acha a pasta pelo XDG_CONFIG_HOME. Por isso a ativação copia o pacote
# (pkgs/vitreus) para lá, em vez de um symlink para o store. Atualizar = mudar o pin `vitreus` no flake.
{ config, lib, pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  user = config.geko.usuario.nome;
  pleamar = inputs.pleamar-vitreus.packages.${system}.pleamar;
  vitreus = pkgs.callPackage ../pkgs/vitreus { src = inputs.vitreus; inherit pleamar user; };
  iris = pkgs.callPackage ../pkgs/iris-colors { };
  # Space Grotesk é a fonte do shell; Audiowide e Mochiy Pop One, a dos temas Retro e UwU.
  fontes = pkgs.google-fonts.override { fonts = [ "SpaceGrotesk" "Audiowide" "MochiyPopOne" ]; };
in {
  imports = [ ./_comum.nix ];

  # A tela de bloqueio do pleamar autentica pelo serviço PAM `pleamar` (cai em `login` sem ele).
  security.pam.services.pleamar = { };
  # O perfil de energia em Controls > Power (powerprofilesctl).
  services.power-profiles-daemon.enable = true;
  # O slider de brilho: brightnessctl grava no backlight pelo grupo video.
  services.udev.packages = [ pkgs.brightnessctl ];
  users.users.${user}.extraGroups = [ "video" ];

  fonts.packages = [ fontes pkgs.nerd-fonts.space-mono ];
  # bin/vitreus-fonts (fonte escolhida em Settings > Theme) procura as fontes do sistema aqui.
  fonts.fontDir.enable = true;
  environment.systemPackages = [ pkgs.adwaita-icon-theme ];

  # ---------- Parte 2: usuário (Home Manager) ----------
  home-manager.users.${user} = { config, lib, pkgs, ... }:
  let
    dest = "${config.xdg.configHome}/pleamar/shells/vitreus";
    keep = scene: "vitreus-keep ${dest}/${scene}";
  in {
    home.packages = [
      pleamar
      vitreus
      iris
      # A lista do install.sh (pacman + AUR), no nome do nixpkgs.
      pkgs.git pkgs.curl pkgs.fontconfig pkgs.imagemagick pkgs.cava pkgs.playerctl pkgs.brightnessctl
      pkgs.hypridle pkgs.libnotify pkgs.xdg-user-dirs pkgs.xdg-utils pkgs.wl-clipboard pkgs.cliphist
      pkgs.awww pkgs.mpvpaper pkgs.ffmpeg pkgs.grim pkgs.slurp pkgs.wf-recorder pkgs.tesseract
      pkgs.sound-theme-freedesktop pkgs.pipewire pkgs.wireplumber pkgs.socat pkgs.procps pkgs.util-linux
    ];

    # Passo 4 e 5 do install.sh: o shell em ~/.config/pleamar/shells/vitreus, gravável.
    # Só copia quando o pacote muda (a cena recarrega a cada arquivo salvo na pasta).
    # palette.plm e wm-palette.plm são do Vitreus (ele as reescreve a partir do wallpaper): nunca sobrescritas.
    home.activation.vitreusShell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dest=${lib.escapeShellArg dest}
      src=${vitreus}/share/vitreus
      if [ -L "$dest" ] || { [ -e "$dest" ] && [ ! -d "$dest" ]; }; then
        errorEcho "$dest existe e não é uma pasta: mova-a e rode o switch de novo"
        exit 1
      fi
      if [ "$(cat "$dest/.nix-source" 2>/dev/null)" != "$src" ]; then
        verboseEcho "Vitreus: copiando $src para $dest"
        run mkdir -p "$dest"
        run ${pkgs.rsync}/bin/rsync -a --delete --chmod=u+w \
          --exclude=/palette.plm --exclude=/wm-palette.plm --exclude=/.nix-source "$src/" "$dest/"
        if [[ ! -v DRY_RUN ]]; then echo "$src" > "$dest/.nix-source"; fi
      fi
      for pal in palette wm-palette; do
        [ -f "$dest/$pal.plm" ] || run install -m644 "$dest/$pal.default.plm" "$dest/$pal.plm"
      done
      # A pasta do log do autostart: sem ela o `>> log` do vitreus-keep falha, ele desiste em
      # silêncio e a cena principal (e todas as binds do hypr_vitreus.lua) nunca sobe.
      run mkdir -p ${lib.escapeShellArg "${config.xdg.dataHome}/pleamar/vitreus"}
    '';

    # Kitty translúcido: o blur vem do decoration.blur do Hyprland, que já pega janelas transparentes.
    # As cores continuam no colors.conf que já estava em ~/.config/kitty.
    programs.kitty = {
      enable = true;
      settings = {
        background_opacity = "0.85";
        background_blur = 1;   # pleamar-wm e outros compositores com ext-background-effect; o Hyprland ignora
      };
      extraConfig = "include colors.conf";
    };

    # O bloqueio após 5 min e antes de suspender, e a tela desligada após 7 (do upstream).
    xdg.configFile."hypr/hypridle.conf".source = "${vitreus}/share/vitreus/pleamar-wm/hypridle.conf";

    # As cenas que o install.sh põe no autostart, cada uma sob o vitreus-keep (que a reinicia se cair).
    # A barra de adesivos e o menu do desktop o próprio shell sobe.
    xdg.configFile."pleamar/autostart".text = lib.mkBefore ''
      ${keep "vitreus.plm"} "$HOME/.local/share/pleamar/vitreus/vitreus.log"
      ${keep "lockscreen/lockscreen.plm"}
      ${keep "wptrans/wptrans.plm"}
      ${keep "desktopclock/desktopclock.plm"}
      ${keep "desktopsysmon/desktopsysmon.plm"}
      ${keep "desktopcava/desktopcava.plm"}
    '';
  };
}
