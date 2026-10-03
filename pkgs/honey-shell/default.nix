{ lib, stdenvNoCC, makeWrapper, python3, pleamar, cava, wl-clipboard, xdg-utils, ddcutil,
  wireplumber, playerctl, brightnessctl, swaylock, swaybg, grim, slurp, procps, systemd, dbus,
  bash, librsvg, mako, util-linux, settings ? {} }:
stdenvNoCC.mkDerivation {
  pname = "honey-shell";
  version = "0.1.0";
  src = lib.cleanSourceWith { src = ./source; filter = path: type: !(lib.elem (baseNameOf path) [ "work" "__pycache__" ]) && !(lib.hasSuffix ".pyc" path); };
  nativeBuildInputs = [ makeWrapper python3 librsvg ];
  buildInputs = [ pleamar ];
  settingsFile = builtins.toJSON settings;
  passAsFile = [ "settingsFile" ];
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/share/honey $out/bin
    cp -r . $out/share/honey/
    chmod -R u+w $out/share/honey
    cp "$settingsFilePath" $out/share/honey/config/user.json
    cd $out/share/honey
    HONEY_MANAGED=1 HONEY_BUILD=1 python3 services/bridge.py prepare > build-config.json
    python3 -c 'import json; c=json.load(open("build-config.json")); assert not c["error"], c["error"]'
    pleamar --check src/honey.plm
    pleamar --check src/reserve.plm
    rsvg-convert fixtures/wallpaper.svg -o fixtures/wallpaper.png
    mkdir -p $out/libexec/honey-apps
    makeWrapper ${python3}/bin/python3 $out/libexec/honey-apps/setsid \
      --add-flags "$out/share/honey/services/app_scope.py" \
      --set HONEY_SYSTEMD_RUN ${systemd}/bin/systemd-run \
      --set HONEY_REAL_SETSID ${util-linux}/bin/setsid \
      --set HONEY_SHELL ${bash}/bin/sh
    makeWrapper ${python3}/bin/python3 $out/bin/honeyctl \
      --add-flags "$out/share/honey/cli.py" \
      --unset PLEAMAR_SOCKETS --unset HONEY_BUILD --set HONEY_MANAGED 1 --set HONEY_CONFIG "$out/share/honey/config/user.json" \
      --set HONEY_SHELL ${bash}/bin/sh \
      --prefix PATH : "$out/bin:${lib.makeBinPath [ pleamar cava wl-clipboard xdg-utils ddcutil wireplumber playerctl brightnessctl swaylock swaybg grim slurp procps systemd dbus mako ]}"
    cat > $out/bin/honey-shell <<EOF
    #!${bash}/bin/bash
    set -e
    umask 077
    unset PLEAMAR_SOCKETS HONEY_BUILD
    export HONEY_MANAGED=1 HONEY_CONFIG="$out/share/honey/config/user.json" HONEY_SHELL=${bash}/bin/sh PYTHONDONTWRITEBYTECODE=1
    export PATH="$out/libexec/honey-apps:$out/bin:${lib.makeBinPath [ python3 pleamar cava wl-clipboard xdg-utils ddcutil wireplumber playerctl brightnessctl procps systemd dbus ]}:\$PATH"
    cd "$out/share/honey"
    exec ${pleamar}/bin/pleamar --scene "$out/share/honey/src/honey.plm" --no-hud --stall 0 "\$@"
    EOF
    chmod +x $out/bin/honey-shell
  '';
  meta = { description = "Honey desktop shell for Pleamar"; mainProgram = "honey-shell"; platforms = lib.platforms.linux; };
}
