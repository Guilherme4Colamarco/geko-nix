# Suporte a AppImage: `./app.AppImage` ou duplo clique funcionam direto (binfmt),
# `appimage-run` roda um arquivo na mão e o Gear Lever integra o app ao menu.
# O nix-ld (modules/core/default.nix) cobre as bibliotecas que o AppImage empacota mal.
{ pkgs, ... }: {
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  environment.systemPackages = [ pkgs.gearlever ];
}
