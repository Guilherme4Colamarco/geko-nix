# Módulos de sistema reutilizáveis, comuns a todos os perfis. O flake importa só este arquivo:
# módulo novo entra na lista abaixo, não em flake.nix.
{ ... }: {
  imports = [
    ./core                       # Fish, ferramentas de CLI, autoUpgrade, nh
    ./core/usuario.nix           # opção geko.usuario.nome
    ./core/comunidade.nix        # NUR, nix-index-database, cache do nix-community
    ./core/appimage.nix          # appimage-run, binfmt e Gear Lever
    ./hardware/nvidia-desktop.nix
    ./services/homelab.nix
    ./services/ghidra-mcp.nix
    ./desktop/options.nix        # geko.desktop.{terminal,fileManager,clipboard}
  ];
}
