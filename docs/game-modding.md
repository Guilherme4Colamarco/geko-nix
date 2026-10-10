# MCPs e skills para mods com IA

As ferramentas do vídeo [The AI unlock has begun](https://www.youtube.com/watch?v=h5zkzon0gM4) são declaradas em `home/game-modding.nix` e empacotadas em `pkgs/game-modding/`.

O módulo é importado pelas escolhas pessoais em `programs/user.nix` e fica habilitado quando a categoria development inclui Codex. Ele vale para todos os perfis de desktop dessa flake.

## Pacotes e versões

| Pacote | Versão | Comando |
| --- | --- | --- |
| Universal Modder | 0.2.0 | `um` |
| Reverse Engineer Anything | 4.1.0 | `rea` |
| Ghidra MCP bridge | 7.0.0 | `bridge-mcp-ghidra` |
| IDA MCP oficial | 20261003.0.1 | `ida-mcp` |

As fontes GitHub usam commits e hashes fixos. O REA usa a distribuição npm 4.1.0 com `package-lock.json` e hash do cache de dependências. As dependências Python são construídas com o Python 3.13 do nixpkgs fixado na flake, incluindo ida-domain 0.5.1, ida-nexus 0.13.3 e zeromcp 1.10.3.

Nenhum servidor depende de downloads no início, de um ambiente Python criado manualmente, ou da pasta de um chat do Codex.

## Skills globais

Home Manager gerencia separadamente 11 diretórios em `~/.agents/skills/`, preservando as outras skills. São as dez skills do Universal Modder e `reverse-engineer-anything` do mesmo pacote REA usado pelo servidor. Os diretórios completos incluem suas referências.

O comando `um kb` aponta para a base de conhecimento incluída na fonte fixada do Universal Modder.

## MCPs no Codex

`programs.codex.mutableSettings = true` mescla os quatro registros declarados com a configuração gravável existente. Ajustes pessoais, plugins e MCPs não declarados neste módulo continuam no arquivo.

- `rea`: servidor local por stdio.
- `ghidra`: servidor local por stdio, conexão a Ghidra em `http://127.0.0.1:8089`.
- `ida`: servidor oficial por stdio, com identificação do cliente `codex`.
- `fal`: serviço remoto em `https://mcp.fal.ai/mcp`, desativado. A chave vem de `FAL_KEY`; não deve ser gravada na flake nem no Nix store.

As instalações dos programas Ghidra e IDA, suas extensões de análise e a chave Fal são requisitos separados. A inicialização dos três servidores pode ser testada sem executar uma análise de binário. Esses MCPs não implementam o núcleo de simulação do projeto Endorphin.

## Validar e aplicar

Na raiz da flake:

```bash
nix build --no-link --no-update-lock-file .#universal-modder .#rea .#ghidra-mcp .#ida-mcp
nix build --no-link --no-update-lock-file .#nixosConfigurations.nixos.config.home-manager.users.geko.home.activationPackage
```

Esses comandos somente constroem e validam. As declarações entram no ambiente no próximo rebuild do perfil escolhido (`nixos`, `niri`, `hyprland`, `pleamar` ou `serpantinum`). Depois da ativação, reabra o Codex para carregar os MCPs.
