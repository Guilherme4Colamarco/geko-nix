# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Flake NixOS (unstable) de uma máquina só, usuário `geko`, idioma do projeto pt-BR. O mapa detalhado do repositório está em [AGENTS.md](AGENTS.md) (flake, perfis, Honey shell, UI pleamar) e o resumo de uso em [README.md](README.md). Leia-os antes de mexer em `desktops/`, `pkgs/honey-shell/` ou `programs/`.

## Antes de qualquer rebuild: conferir o perfil

O hostname é `nixos` em **todos** os perfis, então ele não diz qual está ativo. O perfil é o alvo do flake (`mkDesktop` em `flake.nix`): `nixos`/`serpantinum` (Hyprland + Serpantinum), `pleamar`, `niri`, `hyprland` (os três com Honey), `cosmic`, `mango`, `vitreus` (Hyprland + shell Vitreus) e `vitreus-wm` (pleamar-wm + shell Vitreus). Um `nixos-rebuild switch --flake .` sem alvo cai em `nixos` (Serpantinum) e troca a sessão inteira.

Para descobrir o perfil ativo:

```sh
echo $XDG_CURRENT_DESKTOP            # COSMIC / Hyprland / niri / pleamar
readlink -f /etc/systemd/system/display-manager.service   # greetd = cosmic-greeter; sddm = perfis Honey/Serpantinum
ls /run/current-system/sw/bin | grep -c cosmic            # >0 indica COSMIC instalado
```

Regras:
- Sempre passe o perfil explicitamente: `.#cosmic`, `.#pleamar` etc. Nunca `--flake .` sozinho.
- Se o usuário não disse o perfil e a sessão atual não o revela, pergunte antes de aplicar.
- Aplicar (`switch`) exige `sudo`, que pede senha: o Claude não consegue. Entregue o comando pronto para o usuário rodar e acompanhe com `read_terminal`.
- Perfil novo exige editar `mkDesktop` **e** a lista `nixosConfigurations` em `flake.nix`.
- Módulo de sistema novo (comum a todos os perfis) entra na lista de `modules/default.nix`, não em `flake.nix`.

## Comandos

```sh
# Avaliar sem construir (rápido) — todos os perfis
nix eval .#nixosConfigurations.<perfil>.config.system.build.toplevel.drvPath

# Construir sem ativar
nix build --no-link .#nixosConfigurations.<perfil>.config.system.build.toplevel

# Aplicar (usuário roda; a flake aponta para /home/geko/Documentos/geko-nix)
sudo nixos-rebuild switch --flake .#<perfil>
nh os switch -H <perfil>
sudo nixos-rebuild switch --rollback         # voltar à geração anterior

# Checks
nix build --no-link .#checks.x86_64-linux.software --no-update-lock-file
nix build --no-link .#checks.x86_64-linux.honey-{pleamar,pleamar-core,niri,hyprland}   # VMs do Honey
nix flake check --no-build                   # hoje falha em honey-vm (gtk-3.0/settings.ini sem valor, home/gtk.nix)

# Honey: testes Python (em pkgs/honey-shell/source/) e validação da UI
python3 -m unittest discover tests
pleamar --check pkgs/honey-shell/source/src/honey.plm
```

Não rode `nix flake update` durante refatorações; o lock também é reescrito pelo `system.autoUpgrade` (04:40, `operation=boot`).

## Ferramentas Nix a usar (em vez de adivinhar)

- **MCP `nixos`** (`mcp__nixos__nix`, `nix_versions`): use para qualquer pacote do nixpkgs, opção do NixOS/home-manager, canal ou versão. Os dados de treino estão defasados em relação ao nixpkgs unstable; confirme existência e nome do atributo antes de editar `programs/` ou `home/`.
  - pacote: `{"action":"info","query":"X","channel":"unstable"}`; opção NixOS: `{"action":"search","query":"X","type":"options"}`; home-manager: `{"action":"search","source":"home-manager","query":"X"}`.
- **Skills `nixos` e `nixos-managing`**: carregue ao mexer em módulos, rebuild, rollback ou diagnóstico.
- **`nix eval`/`nix build --no-link`** para validar cada edição antes de pedir o `switch`; `nix repl` / `nix eval .#nixosConfigurations.<perfil>.config.<opção>` para ver o valor final de uma opção.
- **`nh`** (`programs.nh`) está habilitado e fixa a flake em `/home/geko/Documentos/geko-nix`; mover o repo quebra `nh` e o autoUpgrade.
- Pacotes novos: escolha pessoal em `programs/user.nix`; app reutilizável no catálogo da categoria (`programs/{gaming,office,development,studio}.nix`) e atualize `docs/software.md` e `docs/software.pt-BR.md` juntos; Flatpak em `software.flatpak.packages`.

## Arquitetura (o que exige ler vários arquivos)

- `flake.nix` → `mkDesktop <perfil>` monta `hosts/nixos` + `modules/default.nix` + `programs/default.nix` + home-manager + o módulo do perfil em `desktops/`. `specialArgs`: `inputs, unstablePkgs, desktopPkgs, desktopProfile`; módulos home só recebem `inputs`.
- Cada `desktops/*.nix` tem a parte de sistema e, abaixo, `home-manager.users.${config.geko.usuario.nome}`. `serpantinum.nix` e `hyprland-honey.nix` definem ambos `programs.hyprland`: nunca importar juntos. `cosmic` desliga SDDM e não usa Honey. `vitreus.nix` também define `programs.hyprland`; os perfis Vitreus compartilham `_vitreus.nix` e têm inputs próprios (`vitreus`, `pleamar-vitreus`, `pleamar-wm-vitreus`).
- Perfis Honey geram a config inline (não usam `config/`); os atalhos `honeyctl ...` estão repetidos em três arquivos e precisam ser sincronizados à mão.
- Categorias de software (`software.<cat>.{enable,apps,extraPackages}`) são desligadas por padrão; `apps` substitui o conjunto inicial, nomes inválidos falham por assertion.
- `pkgs/honey-shell/source/src/themes/active.plm` é **gerado**; não editar. `hosts/nixos/hardware-configuration.nix` também não.
- Backup `*.before-geko-nix` já existente bloqueia a ativação do home-manager.
- Symlinks `result*` na raiz são artefatos de build; não editar nem commitar.
- Hash fixo (Proton, sqldeveloper): atualize `version`, `url` e `hash` juntos.
