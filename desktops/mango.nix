# Perfil Mango (alvo `mango`): compositor mangowm (dwl/scenefx) + Marea como shell.
# O Marea (pleamar) faz a parte de desktop: notificações, bandeja, central de controle,
# finder, prints, lock e wallpaper. O Mango entra com tile, Alt+Tab com miniaturas,
# minimizar, overview e efeitos. Sem Honey e sem barra: tags pela overview e atalhos.
# Parte 1 = sistema (NixOS); parte 2 = usuário (Home Manager: ~/.config/mango/config.conf).
{ config, pkgs, inputs, ... }:
let
  marea = inputs.pleamar-wm.inputs.marea.packages.${pkgs.stdenv.hostPlatform.system}.marea;
in {
  imports = [ ./_comum-honey.nix ];

  programs.mango.enable = true;
  services.displayManager.defaultSession = "mango";

  environment.systemPackages = [
    marea
    pkgs.wireplumber pkgs.playerctl pkgs.brightnessctl
    pkgs.polkit_gnome
    # Seletor de tela do xdg-desktop-portal-wlr (ele procura slurp, rofi…).
    pkgs.slurp
  ];

  # O lock do pleamar autentica no serviço PAM `pleamar` se existir (senão `login`).
  security.pam.services.pleamar = { };

  # Portais: o módulo programs.mango do nixpkgs já mapeia XDG_CURRENT_DESKTOP=mango
  # (gtk por padrão, wlr para compartilhar tela, gnome-keyring para segredos).

  # ---------- Parte 2: usuário (Home Manager) ----------
  home-manager.users.${config.geko.usuario.nome} = { lib, pkgs, osConfig, ... }:
  let
    mango = config.programs.mango.package;
    m = "${marea}/bin/marea";
    wpctl = "${pkgs.wireplumber}/bin/wpctl";
    # Print copia direto para a área de transferência (grim + slurp + wl-copy).
    copiar = pkgs.writeShellScript "print-para-clipboard" ''
      export PATH=${lib.makeBinPath [ pkgs.grim pkgs.slurp pkgs.wl-clipboard pkgs.libnotify ]}
      if [ "$1" = regiao ]; then
        area=$(slurp) || exit 0
        grim -g "$area" - | wl-copy --type image/png
      else
        grim - | wl-copy --type image/png
      fi && notify-send -a Print "Captura copiada" "Cole com Ctrl+V"
    '';
    playerctl = "${pkgs.playerctl}/bin/playerctl";
    brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
    tags = lib.range 1 9;

    conf = ''
      # Gerado por desktops/mango.nix. Edite lá; aqui é só leitura.

      # ── sessão ──────────────────────────────────────────────
      env=XCURSOR_THEME,${osConfig.geko.desktop.cursor.name}
      env=XCURSOR_SIZE,${toString osConfig.geko.desktop.cursor.size}
      env=HYPRCURSOR_THEME,${osConfig.geko.desktop.cursor.name}
      env=HYPRCURSOR_SIZE,${toString osConfig.geko.desktop.cursor.size}
      env=QT_QPA_PLATFORM,wayland;xcb

      # ── NVIDIA (o resto — LIBVA, __GLX, NVD — vem de modules/hardware/nvidia-desktop.nix) ─
      env=GBM_BACKEND,nvidia-drm
      env=__GL_GSYNC_ALLOWED,1
      env=__GL_VRR_ALLOWED,1
      # Menos fila de quadros no driver = menos latência de entrada.
      env=__GL_MaxFramesAllowed,1
      env=__GL_SHADER_DISK_CACHE_SIZE,12000000000
      # DLSS/Reflex em jogos via Proton.
      env=PROTON_ENABLE_NVAPI,1
      env=DXVK_ENABLE_NVAPI,1
      # Sincronização explícita (drm_syncobj): o driver NVIDIA ≥ 555 precisa dela
      # para não ter stutter/flicker em Xwayland e Vulkan. Exige relogar.
      syncobj_enable=1
      # Se o tearing abaixo não funcionar nesta placa, a doc do Mango manda
      # descomentar isto (desliga atomic modesetting; teste antes de manter):
      # env=WLR_DRM_NO_ATOMIC,1
      exec-once=${m} start
      exec-once=${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1

      # ── entrada e monitor ───────────────────────────────────
      xkb_rules_layout=br
      repeat_rate=25
      repeat_delay=400
      numlockon=1
      mouse_accel_profile=1
      mouse_accel_speed=0.0
      tap_to_click=1
      trackpad_natural_scrolling=1
      trackpad_disable_while_typing=1
      cursor_size=${toString osConfig.geko.desktop.cursor.size}
      # vrr:0 aqui + vrr_only_fullscreen nas regras de jogo = G-Sync só no jogo em tela
      # cheia (VRR no desktop inteiro faz o cursor e as animações piscarem).
      monitorrule=name:^DP-1$,width:1920,height:1080,refresh:165.003,x:0,y:0,scale:1.25,vrr:0,primary:1

      # ── jogos ───────────────────────────────────────────────
      # Tearing (vsync off) só para janela em tela cheia que pedir ou for forçada.
      allow_tearing=2
      # Xwayland (Steam, Proton, jogos antigos) na resolução nativa, sem o borrão do 1.25.
      xwayland_ignore_scale=1
      xwayland_persistence=1
      allow_shortcuts_inhibit=1

      # ── comportamento (mais "desktop", menos "tiling purista") ─
      sloppyfocus=0
      warpcursor=0
      focus_on_activate=1
      focus_cross_monitor=1
      enable_floating_snap=1
      snap_distance=24
      drag_tile_to_tile=1
      float_full_to_top=1
      idleinhibit_when_fullscreen=1

      # ── layout: tile (master-stack) em todas as tags ────────
      tag_num=9
      new_is_master=0
      default_mfact=0.55
      default_nmaster=1
      smartgaps=0
      ${lib.concatMapStringsSep "\n" (i: "tagrule=id:${toString i},layout_name:tile") tags}

      # ── overview ────────────────────────────────────────────
      overviewgappi=12
      overviewgappo=40
      enable_hotarea=1
      hotarea_size=6
      hotarea_disable_on_fullscreen=1

      # ── visual (paleta mel/âmbar do Honey) ──────────────────
      borderpx=2
      border_radius=10
      no_radius_when_single=0
      no_border_when_single=1
      gappih=6
      gappiv=6
      gappoh=10
      gappov=10
      rootcolor=0x24201bff
      bordercolor=0x3a332aff
      focuscolor=0xffdb85ff
      urgentcolor=0xef7a66ff
      maximizescreencolor=0xffad28ff
      scratchpadcolor=0xb97912ff
      globalcolor=0x9ed6bdff
      overlaycolor=0x9ed6bdff
      dropcolor=0xffdb8555
      splitcolor=0xffad28ff

      # Blur nas áreas transparentes de janelas e camadas (Marea, menus). optimized=0
      # borra o conteúdo real que está atrás, não só o wallpaper; custa mais GPU.
      blur=1
      blur_layer=1
      blur_optimized=0
      blur_params_num_passes=3
      blur_params_radius=6
      blur_params_noise=0.02
      blur_params_brightness=0.95
      blur_params_contrast=0.95
      blur_params_saturation=1.15
      shadows=1
      layer_shadows=0
      shadow_only_floating=1
      shadows_size=18
      shadows_blur=20
      shadows_position_y=4
      shadowscolor=0x00000088
      focused_opacity=1.0
      unfocused_opacity=1.0

      # Animações curtas; nas camadas, deixa o Marea animar sozinho.
      animations=1
      layer_animations=0
      animation_type_open=zoom
      animation_type_close=zoom
      animation_fade_in=1
      animation_fade_out=1
      tag_animation_direction=1
      zoom_initial_ratio=0.85
      zoom_end_ratio=0.9
      animation_duration_open=250
      animation_duration_close=220
      animation_duration_move=280
      animation_duration_tag=300
      animation_duration_focus=0
      animation_curve_open=0.46,1.0,0.29,1
      animation_curve_move=0.46,1.0,0.29,1
      animation_curve_tag=0.46,1.0,0.29,1
      animation_curve_close=0.08,0.92,0,1

      # ── regras de janela ────────────────────────────────────
      windowrule=isterm:1,appid:^kitty$
      windowrule=isfloating:1,width:820,height:560,appid:^(org.pulseaudio.pavucontrol|pavucontrol)$
      windowrule=isfloating:1,width:820,height:560,appid:^(nm-connection-editor|.blueman-manager-wrapped|blueman-manager)$
      windowrule=isfloating:1,appid:^(org.gnome.FileRoller|file-roller|org.gnome.Calculator|xdg-desktop-portal-gtk)$
      windowrule=isfloating:1,title:^(Open|Save|Abrir|Salvar|Open File|Abrir arquivo|Salvar como).*
      windowrule=isfloating:1,isglobal:1,isoverlay:1,width:480,height:270,offsetx:90,offsety:85,title:^(Picture in Picture|Picture-in-Picture)$
      layerrule=noanim:1,noblur:1,noshadow:1,layer_name:selection

      # Jogos (Steam/Proton = steam_app_N, Gamescope, nativos comuns): sem efeitos,
      # tearing + VRR em tela cheia, cursor preso na janela e tela sem apagar.
      ${lib.concatMapStringsSep "\n" (match: "windowrule=force_tearing:1,vrr_only_fullscreen:1,confine_pointer:1,idleinhibit_when_focus:1,isnoanimation:1,noblur:1,isnoborder:1,isnoshadow:1,isnoradius:1,${match}") [
        "appid:^steam_app_[0-9]+$"
        "appid:^(gamescope|.gamescope-wrapped)$"
        "appid:^(Minecraft.*|org.prismlauncher.PrismLauncher|osu!|cs2|dota2|hl2_linux)$"
        "title:^(Minecraft.*|Counter-Strike 2)$"
      ]}
      # Cliente da Steam: lista de amigos e diálogos flutuando.
      windowrule=isfloating:1,width:360,height:720,appid:^steam$,title:^(Friends List|Lista de amigos)$
      windowrule=isfloating:1,appid:^steam$,title:^(Steam - News|Steam Settings|Configurações do Steam|Properties.*|Propriedades.*)$

      # ── atalhos: Marea ──────────────────────────────────────
      bind=SUPER,space,spawn,${m} search
      bind=SUPER,d,spawn,${m} search
      bind=SUPER,Escape,spawn,${m} lock
      bind=NONE,Print,spawn,${copiar} regiao
      bind=SHIFT,Print,spawn,${copiar} tela
      bind=CTRL,Print,spawn,${m} shot_region
      bind=SUPER+SHIFT,c,spawn,${m} record_toggle

      # ── atalhos: apps ───────────────────────────────────────
      bind=SUPER,Return,spawn,${pkgs.kitty}/bin/kitty
      bind=SUPER,e,spawn,${pkgs.nautilus}/bin/nautilus

      # ── atalhos: janelas (estilo tradicional) ───────────────
      bind=SUPER,q,killclient,
      bind=ALT,F4,killclient,
      bind=ALT,Tab,switcher,next
      bind=ALT+SHIFT,Tab,switcher,prev
      bind=SUPER+ALT,Tab,switcher,all_next
      bind=SUPER,Tab,toggleoverview,
      bind=SUPER,Up,togglemaximizescreen,
      bind=SUPER,Down,minimized,
      bind=SUPER,m,minimized,
      bind=SUPER+SHIFT,m,restore_minimized,
      bind=SUPER,f,togglefullscreen,
      bind=SUPER+SHIFT,f,togglefloating,
      bind=SUPER,c,centerwin,
      bind=SUPER,g,toggleglobal,
      bind=SUPER,grave,toggle_scratchpad,
      bind=SUPER+SHIFT,Return,zoom,

      # ── atalhos: tile ───────────────────────────────────────
      bind=SUPER,Left,focusdir,left
      bind=SUPER,Right,focusdir,right
      bind=SUPER+ALT,Up,focusdir,up
      bind=SUPER+ALT,Down,focusdir,down
      bind=SUPER+SHIFT,Left,exchange_client,left
      bind=SUPER+SHIFT,Right,exchange_client,right
      bind=SUPER+SHIFT,Up,exchange_client,up
      bind=SUPER+SHIFT,Down,exchange_client,down
      bind=SUPER,minus,setmfact,-0.05
      bind=SUPER,equal,setmfact,+0.05

      # Modo vim (hjkl), junto das setas.
      bind=SUPER,h,focusdir,left
      bind=SUPER,j,focusdir,down
      bind=SUPER,k,focusdir,up
      bind=SUPER,l,focusdir,right
      bind=SUPER+SHIFT,h,exchange_client,left
      bind=SUPER+SHIFT,j,exchange_client,down
      bind=SUPER+SHIFT,k,exchange_client,up
      bind=SUPER+SHIFT,l,exchange_client,right
      bind=SUPER+CTRL,h,setmfact,-0.05
      bind=SUPER+CTRL,l,setmfact,+0.05
      bind=SUPER+CTRL,j,viewtoright_have_client,0
      bind=SUPER+CTRL,k,viewtoleft_have_client,0
      bind=SUPER+ALT,h,focusmon,left
      bind=SUPER+ALT,l,focusmon,right
      bind=SUPER,i,incnmaster,+1
      bind=SUPER,o,incnmaster,-1
      bind=SUPER,n,switch_layout,
      bind=SUPER+SHIFT,t,setlayout,tile

      # ── atalhos: tags ───────────────────────────────────────
      ${lib.concatMapStringsSep "\n" (i: let n = toString i; in "bind=SUPER,${n},view,${n},0\nbind=SUPER+SHIFT,${n},tag,${n},0") tags}
      bind=SUPER,0,view,00,0
      bind=SUPER+CTRL,Left,viewtoleft_have_client,0
      bind=SUPER+CTRL,Right,viewtoright_have_client,0
      bind=SUPER+CTRL+SHIFT,Left,tagtoleft,0
      bind=SUPER+CTRL+SHIFT,Right,tagtoright,0
      bind=SUPER+CTRL,Up,focusmon,next
      bind=SUPER+CTRL+SHIFT,Up,tagmon,next

      # ── atalhos: mídia (funcionam com a tela bloqueada) ─────
      bindl=NONE,XF86AudioRaiseVolume,spawn,${wpctl} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
      bindl=NONE,XF86AudioLowerVolume,spawn,${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindl=NONE,XF86AudioMute,spawn,${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindl=NONE,XF86AudioMicMute,spawn,${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindl=NONE,XF86AudioPlay,spawn,${playerctl} play-pause
      bindl=NONE,XF86AudioPause,spawn,${playerctl} play-pause
      bindl=NONE,XF86AudioNext,spawn,${playerctl} next
      bindl=NONE,XF86AudioPrev,spawn,${playerctl} previous
      bindl=NONE,XF86MonBrightnessUp,spawn,${brightnessctl} set 5%+
      bindl=NONE,XF86MonBrightnessDown,spawn,${brightnessctl} set 5%-

      # ── sessão ──────────────────────────────────────────────
      bind=SUPER+SHIFT,r,reload_config,
      bind=SUPER+SHIFT,e,quit,

      # ── mouse, roda e gestos ────────────────────────────────
      mousebind=SUPER,btn_left,moveresize,curmove
      mousebind=SUPER,btn_right,moveresize,curresize
      mousebind=SUPER,btn_middle,togglemaximizescreen,0
      axisbind=SUPER,UP,viewtoleft_have_client
      axisbind=SUPER,DOWN,viewtoright_have_client
      gesturebind=none,left,3,focusdir,left
      gesturebind=none,right,3,focusdir,right
      gesturebind=none,right,4,viewtoleft_have_client
      gesturebind=none,left,4,viewtoright_have_client
      gesturebind=none,up,4,enteroverview
      gesturebind=none,down,4,leaveoverview
    '';

    # Escreve a config e valida no build: `mango -p` recusa palavra-chave ou dispatch inválido.
    configFile = pkgs.runCommand "mango-config.conf" { passAsFile = [ "conf" ]; inherit conf; } ''
      cp "$confPath" $out
      ${mango}/bin/mango -c $out -p
    '';
  in {
    xdg.configFile."mango/config.conf".source = configFile;
  };
}
