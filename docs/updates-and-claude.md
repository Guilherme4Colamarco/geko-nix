# Atualizações e Claude

O auto upgrade usa o perfil que foi escolhido no flake: Niri continua Niri, Pleamar continua Pleamar e Hyprland continua Hyprland.

O timer roda diariamente às 04:40, com atraso aleatório de até 20 minutos e recuperação de execuções perdidas. Atualiza nixpkgs, nixpkgs-unstable, Home Manager e o empacotamento do Claude Desktop, prepara uma geração com `nixos-rebuild boot` e nunca reinicia a máquina automaticamente. A nova geração entra no próximo reinício manual. As configurações locais não são substituídas por um git pull; o timer lê este checkout e atualiza seu flake.lock.

Claude Code vem de nixpkgs-unstable (`claude` no terminal). Claude Desktop usa o pacote Linux oficial da Anthropic, adaptado ao Nix pela entrada `claude-desktop-app`, com sua revisão e hash registrados em flake.lock. Procure **Claude** no launcher ou execute `claude-desktop`.

Para acessar a conta, entre pelo próprio aplicativo/CLI. Cowork requer virtualização habilitada no firmware; o grupo kvm e o módulo vhost_vsock estão declarados para a próxima inicialização.

Verificação após reiniciar:

```sh
systemctl list-timers nixos-upgrade.timer
systemctl status nixos-upgrade.timer
journalctl -u nixos-upgrade.service
claude --version
```

As opções ficam em `modules/core/default.nix`, e as seleções em `programs/user.nix` (catálogo em `programs/development.nix`). Para aplicar apenas no próximo boot, sem interromper a sessão atual:

```sh
sudo nixos-rebuild boot --flake /home/geko/Documentos/geko-nix#niri
```

Referências: https://code.claude.com/docs/en/desktop-linux e https://github.com/poeck/claude-desktop-nix-flake.
