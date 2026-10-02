# Validação — 2026-10-02

- Build completo dos outputs `nixos` e `nixos-pleamar`: sucesso.
- `nixos-serpantinum` é alias do alvo `nixos`.
- Usuario `geko`, `/home/geko`, locale pt_BR.UTF-8, fuso America/Sao_Paulo.
- Arquivo de hardware/discos/swap preservado sem diff; stateVersion 26.05.
- NVIDIA aberto, modesetting, aceleração 32-bit e driver estável.
- Docker habilitado, grupo docker, Compose e daemon configurados.
- NetBeans 30 e JDK 21 confirmados por avaliação.
- SQL Developer 24.3.1 empacotado com JDK 17 próprio.
- Antigravity IDE/CLI, ChatGPT Desktop, AstroNvim e variantes Proton mantidos.
- Fish: sintaxe validada; sem autostart de Hyprland ou QS.
- Pleamar: Hyprland desabilitado, withMarea=true, sessão pleamar-wm registrada.
- Closure de ambos os sistemas: sem Hermes, Ryoku, xfce4-session e xfdesktop.
- `git diff --check`: sucesso.
- Nenhum switch/test/boot nem ativação de Home Manager executado.

Artefatos:

- Serpantinum: `/nix/store/6sdw96dzxx6v9yk21qx3zkq8rn6zghcs-nixos-system-nixos-26.05.20260928.7fc6f2c`
- Pleamar + Marea: `/nix/store/m99jm9rps1220ld9nk7n26hdqa9hhsqc-nixos-system-nixos-26.05.20260928.7fc6f2c`

A integração usa o módulo oficial de Pleamar-WM, que fornece também Pleamar
runtime e Marea. Os inputs são fixados no lock. O projeto Pleamar é um perfil
experimental; estes builds não comprovam estabilidade gráfica em NVIDIA.

Pendentes após ativação: login, suspensão, som, clipboard, bloqueio de tela,
portais, Docker em execução, conexão SQL e jogos. Há avisos upstream de nomes
depreciados do conjunto xorg; eles não impediram os builds.
