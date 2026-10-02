# geko-nix

Configuração pessoal de NixOS do geko. Alvo da flake: `nixos`.

## Estado inicial

Este primeiro registro preserva a configuração existente: Ryoku, fallback
XFCE, integração Hermes, ferramentas de desenvolvimento, AstroNvim e gaming.
Versionar estes arquivos não ativa uma geração do sistema.

## Organização atual

- `flake.nix` e `flake.lock`: inputs e composição do sistema.
- `configuration.nix`: sistema, usuário, localização e drivers.
- `hardware-configuration.nix`: discos e hardware específicos desta máquina.
- `ryoku.nix`: módulo gerenciado pelo instalador Ryoku.
- `programs/`: aplicativos e ferramentas por categoria.
- `agents/`: integração Hermes existente, a remover na migração.

## Próxima migração

- Perfis de desktop selecionáveis, incluindo Serpantinum.
- Remover XFCE e Hermes Agent, preservando dados pessoais.
- Aproveitar Fish e o core do OrbitOS, sem Orbit CLI.
- Aproveitar o módulo NVIDIA desktop e a organização de gaming do OrbitOS.
- Incluir Antigravity IDE, Docker e ferramentas da faculdade.

Esses itens são decisões para a próxima etapa, ainda não implementados.

## Construir sem ativar

```sh
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

Não aplique esta configuração em outra máquina sem adaptar os discos,
hardware e usuário. Não versione credenciais, chaves privadas ou estados
privados de aplicativos.
