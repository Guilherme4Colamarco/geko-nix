# Vitreus (natepayn3/Vitreus, MIT): shell pleamar de vidro. `src` é o input `vitreus` do flake.
# $out/share/vitreus é a pasta do shell com os caminhos de Arch trocados pelos do NixOS; a
# ativação do Home Manager (desktops/_vitreus.nix) a copia, gravável, para
# ~/.config/pleamar/shells/vitreus, porque o Vitreus grava palette.plm ali.
# $out/bin traz os ajudantes que o shell chama pelo PATH (vitreus-clipimg, -term, -sysmon...).
# Os --replace-fail quebram o build se o upstream mudar um desses caminhos: confira o novo e ajuste.
{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  glib,
  sound-theme-freedesktop,
  pleamar,
  src,
  user ? "geko",
}:
let
  python = python3.withPackages (p: [ p.pygobject3 p.pyte ]);
in
stdenvNoCC.mkDerivation {
  pname = "vitreus";
  version = "unstable-${builtins.substring 0 8 (src.rev or "local")}";
  inherit src;

  nativeBuildInputs = [ makeWrapper pleamar ];
  buildInputs = [ python ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    dest=$out/share/vitreus
    mkdir -p $dest
    cp -r . $dest
    # Só o README usa: 19 MB de capturas e o banner.
    rm -rf $dest/assets/screenshots $dest/assets/banner.jpeg $dest/.git
    # O instalador do Arch não serve aqui (o Nix faz o papel dele).
    rm -f $dest/install.sh $dest/pleamar-wm/install-session.sh
    chmod -R u+w $dest

    substituteInPlace $dest/vitreus.luau \
      --replace-fail '"/usr/share/sounds/freedesktop/stereo/"' '"${sound-theme-freedesktop}/share/sounds/freedesktop/stereo/"' \
      --replace-fail '{ "/usr/share/applications",' '{ "/run/current-system/sw/share/applications", "/etc/profiles/per-user/${user}/share/applications",'
    substituteInPlace $dest/bin/vitreus-fonts \
      --replace-fail 'dirs = ["/usr/share/fonts", "/usr/local/share/fonts", d]' \
                     'dirs = ["/run/current-system/sw/share/X11/fonts", "/etc/profiles/per-user/${user}/share/fonts", d]'
    substituteInPlace $dest/pleamar-wm/hyprctl \
      --replace-fail 'exec /usr/bin/hyprctl' 'exec /run/current-system/sw/bin/hyprctl'

    # O pleamar do Nix é um wrapper (`exec -a "$0"`): chamado pelo PATH, o processo aparece com o
    # caminho completo, não como `pleamar`. Os pgrep/pkill do Vitreus (reinício da barra ao trocar
    # de monitor, atualização, vitreus-keep) procuram "^pleamar --scene": aceita qualquer caminho antes.
    grep -rlF '^pleamar --scene' $dest > $TMPDIR/procs
    test -s $TMPDIR/procs
    xargs sed -i 's|\^pleamar --scene|^[^ ]*pleamar --scene|g' < $TMPDIR/procs
    ! grep -rF '^pleamar --scene' $dest

    patchShebangs $dest/bin $dest/pleamar-wm/hyprctl
    # O agente de polkit usa Gio/GLib pelo GObject Introspection.
    wrapProgram $dest/bin/vitreus-polkit-agent \
      --prefix GI_TYPELIB_PATH : "${lib.getLib glib}/lib/girepository-1.0"

    mkdir -p $out/bin
    for f in vitreus-clipimg vitreus-fonts vitreus-keep vitreus-polkit-agent vitreus-sysmon vitreus-term; do
      ln -s $dest/bin/$f $out/bin/$f
    done
    runHook postInstall
  '';

  # As cenas precisam passar no pleamar desta versão antes de chegar ao switch.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    # Numa cópia com as paletas que a ativação cria (a tela de bloqueio e a cena do WM as importam).
    cp -r $out/share/vitreus $TMPDIR/shell
    chmod -R u+w $TMPDIR/shell
    for pal in palette wm-palette; do cp $TMPDIR/shell/$pal.default.plm $TMPDIR/shell/$pal.plm; done
    for scene in vitreus.plm lockscreen/lockscreen.plm wptrans/wptrans.plm desktopclock/desktopclock.plm \
                 desktopsysmon/desktopsysmon.plm desktopcava/desktopcava.plm desktopnotes/desktopnotes.plm \
                 desktopmenu/desktopmenu.plm pleamar-wm/wm/session.plm; do
      echo "pleamar --check $scene"
      pleamar --check $TMPDIR/shell/$scene 2>&1 | grep -v '^note' || true
      pleamar --check $TMPDIR/shell/$scene > /dev/null 2>&1
    done
    runHook postInstallCheck
  '';

  meta = {
    description = "Liquid-glass desktop shell for pleamar";
    homepage = "https://github.com/natepayn3/Vitreus";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
