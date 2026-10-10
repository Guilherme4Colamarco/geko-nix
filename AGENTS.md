# Mapa do repositório geko-nix (para agentes)

Flake NixOS unstable de uma máquina só (usuário `geko`, NVIDIA + AMD CPU, btrfs). Um sistema, vários **perfis de desktop**, escolhidos pela configuração do flake. Idioma do projeto: pt-BR.

> Gerado por análise em 2026-10-03 (branch `desktop-profiles`, com mudanças não commitadas). Confira o código antes de confiar em detalhes finos.

## 1. Visão geral rápida

| Área | Onde | Detalhe |
|---|---|---|
| Flake, núcleo, programas | `flake.nix`, `configuration.nix`, `modules/{core,hardware,services}`, `programs/` | seção 2 |
| Desktop e home-manager | `desktops/`, `home/`, `config/` | seção 3 |
| Honey shell (Python e pacote) | `pkgs/honey-shell/` | seção 4 |
| Honey UI (pleamar `.plm`/`.luau`) | `pkgs/honey-shell/source/src/`, `docs/pleamar/` | seção 5 |
| Pacotes soltos | `pkgs/{sqldeveloper,pleamar-wm}.nix`, `pkgs/pleamar-linear-framebuffer.patch` | seção 2 |
| Testes de integração | `tests/honey-vm.nix` | seções 2 e 4 |

Comandos úteis:
- Só construir: `nix build .#nixosConfigurations.nixos.config.system.build.toplevel`
- Aplicar: `nixos-rebuild switch --flake .#<perfil>` ou `nh os switch -H <perfil>`
- Check de programas: `nix build --no-link .#checks.x86_64-linux.software --no-update-lock-file`
- Checks (VMs do Honey): `nix build --no-link .#checks.x86_64-linux.honey-{pleamar,pleamar-core,niri,hyprland}`
- Atualizar um input: `nix flake update <input>`
- Testes Python do Honey: em `pkgs/honey-shell/source/`, `python3 -m unittest discover tests`
- Validar UI: `pleamar --check pkgs/honey-shell/source/src/honey.plm`

## 2. Flake e núcleo NixOS

- `flake.nix`: função `mkDesktop <perfil>` monta tudo. `specialArgs = { inputs, unstablePkgs, desktopPkgs, desktopProfile }`.
  - `nixosConfigurations`: `nixos` e `serpantinum` (idênticos), `pleamar`, `niri`, `hyprland`, `cosmic`.
  - `checks.x86_64-linux`: `honey-pleamar`, `honey-pleamar-core` (sem captura), `honey-niri`, `honey-hyprland`.
  - `packages.x86_64-linux` expõe `universal-modder`, `rea`, `ghidra-mcp` e `ida-mcp` (`pkgs/game-modding/`). Não há overlays. Pacotes próprios entram por `callPackage`/`import`.
  - O mapa de perfis está duplicado (if/else em `mkDesktop` e a lista de `nixosConfigurations`). Perfil novo exige os dois.
- Módulos comuns (todos os perfis): nix-flatpak, home-manager, `configuration.nix`, `modules/core`, `nvidia-desktop`, `homelab`, `desktop/options`, `programs/default.nix`, e um bloco inline do home-manager (`useGlobalPkgs`, `useUserPackages`, `backupFileExtension="before-geko-nix"`, `users.geko = import ./home`).
- Inputs: `nixpkgs` (nixos-unstable), `home-manager` (master), `nixpkgs-unstable` (alias do principal), `desktopPkgs` (= `unstablePkgs`; fornece hyprland e portal-hyprland), `serpantinum`, `pleamar-wm` (+ `marea`), `chatgpt-desktop-app`, `claude-desktop-app`, `nix-flatpak`, `astrovim` (`flake=false`). Vários pinados por rev.
- Arquivos:
  - `configuration.nix`: boot, rede, locale pt_BR, SDDM, pipewire, CUPS, i2c, usuário `geko`, `stateVersion` 26.05. `hardware-configuration.nix` é gerado, não editar.
  - `modules/core/default.nix`: fish, nix-ld, CLI, `system.autoUpgrade` (04:40, `operation=boot`, reescreve `flake.lock`), `programs.nh` (flake fixo em `/home/geko/Documentos/geko-nix`).
  - `modules/services/homelab.nix`: modo servidor caseiro (Tailscale + SSH só por chave), **desligado por padrão**; liga com `geko.homelab.enable = true` e `geko.homelab.ssh.authorizedKeys`, firewall abre só a porta 22 em `tailscale0`.
  - `modules/hardware/nvidia-desktop.nix`: tudo em `mkDefault`. `modules/services/docker.nix`: autoPrune `--all` e grupo docker (equivale a root).
  - `programs/default.nix`: importa `user.nix`, `flatpak.nix` e as categorias `gaming.nix`, `office.nix`, `development.nix`, `studio.nix`. Opções `software.<category>.{enable,apps,extraPackages}`; todas desligadas por padrão. Listas explícitas substituem os defaults; enums rejeitam nomes inválidos sem forçar pacotes não selecionados.
  - `programs/user.nix`: escolhas pessoais explícitas, apps externos, KVM do Claude Desktop e imports pessoais AstroNvim/skills condicionados às seleções. Aplicativos comuns vão ao Home Manager. `programs/proton.nix` guarda hashes existentes; Steam/Java/controles/firewall são integrações NixOS. Docker é importado por development e exige `enable` + `docker.enable`.
  - `programs/flatpak.nix`: união deduplicada dos IDs pessoais e das categorias, instalação de sistema, sem remover apps manuais. Catálogos e regras equivalentes em `docs/software.md` e `docs/software.pt-BR.md`; validação em `docs/software-validation.md` e `tests/software.nix` (`checks.x86_64-linux.software` e `software-personal`).
  - `pkgs/pleamar-wm.nix`: `overrideAttrs` com o patch de framebuffer. Atualizar o pin pode quebrar o patch.
- Options próprias: `geko.desktop.{terminal,fileManager,clipboard.enable}` (`modules/desktop/options.nix`) e `software.*` (`programs/`). O namespace antigo de jogos foi removido.
- Onde adicionar: escolha pessoal em `programs/user.nix`; app reutilizável no catálogo lazy da categoria; Flatpak em `software.flatpak.packages`; pacote próprio em `pkgs/` com `callPackage`. Atualize ambos os guias ao mudar o catálogo. Não atualize o lock durante refatorações. Componentes essenciais de sessão/hardware ficam fora das categorias.
- Gotchas:
  - Hash fixo (Proton, sqldeveloper): atualizar `version`, `url` e `hash` juntos.
  - Um backup `*.before-geko-nix` já existente bloqueia a ativação do home-manager.
  - O autoupdate prepara o próximo boot; builds manuais de validação não ativam nem atualizam o lock.

## 3. Desktop e home-manager

| Perfil (`.#X`) | Módulo NixOS | Home | Sessão |
|---|---|---|---|
| `nixos`/`serpantinum` | `desktops/serpantinum.nix` | inline no mesmo arquivo (usa `inputs.serpantinum.homeManagerModules.default`) | Hyprland (`desktopPkgs`) com shell Serpantinum |
| `pleamar` | `desktops/pleamar.nix` | no mesmo arquivo (parte 2) | pleamar-wm (`withMarea=false`) |
| `niri` | `desktops/niri-honey.nix` | no mesmo arquivo (parte 2) | niri (unstable) |
| `hyprland` | `desktops/hyprland-honey.nix` | no mesmo arquivo (parte 2) | Hyprland puro |
| `cosmic` | `desktops/cosmic.nix` | só o Home comum (`home/default.nix`) | COSMIC (cosmic-greeter; SDDM desligado) |

- Não existe option de perfil. O perfil é a escolha do alvo do flake.
- `cosmic` não importa Honey. Liga `services.desktopManager.cosmic` e `services.displayManager.cosmic-greeter`, e força `services.displayManager.sddm.enable = false`. Ajustes de painel, tema e monitor persistem em `~/.config/cosmic/`.
- `pleamar`, `niri` e `hyprland` são perfis "Honey": importam `desktops/_comum-honey.nix` (pam swaylock, fontes, dconf; upower/keyring/polkit vêm de `desktops/_comum.nix`) e ligam `programs.honeyShell` (`home/honey.nix`) com `settings.compositor`. O `home/honey.nix` define os serviços de usuário `honey-{reserve,shell,wallpaper,polkit,sleep-lock}` (as notificações são do próprio shell; o mako foi removido) no `honey-session.target`, além do swaylock em âmbar.
- Cada arquivo de `desktops/` tem a parte de sistema e, abaixo, `home-manager.users.${config.geko.usuario.nome} = { ... }` (a opção `geko.usuario.nome`, padrão `geko`, vem de `modules/core/usuario.nix`), exceto `cosmic.nix`, que só usa o Home comum. Nos módulos home só `inputs` está disponível como specialArg.
- `home/default.nix`: identidade, `stateVersion`, Fish e GTK. AstroNvim (`home/astronvim.nix`), skills do Claude (`home/claude-code.nix`) e ferramentas de mods (`home/game-modding.nix`) são imports pessoais em `programs/user.nix`; `mcp-nixos` está na lista pessoal. O módulo de mods instala 11 skills globais em `~/.agents/skills/` e mescla MCPs no Codex com `mutableSettings`; detalhes em `docs/game-modding.md`.
- `config/`: `fish/config.fish` (`readFile` em `home/fish.nix`), `starship.toml`, `hyprland/serpantinum.lua` (`readFile` em `desktops/serpantinum.nix`, vira `~/.config/hypr/hyprland.lua`). Os perfis Honey NÃO usam `config/`: geram tudo inline em `desktops/*-honey.nix` e `desktops/pleamar.nix`. O pleamar gera `~/.config/pleamar/{keys.conf,session.conf,autostart,wm}`.
- Onde mexer:
  - **Keybinds**: serpantinum em `config/hyprland/serpantinum.lua` e `execbind` em `desktops/serpantinum.nix`; Honey em `desktops/{hyprland-honey,niri-honey,pleamar}.nix`. A tabela de teclas de mídia é única (`desktops/media-keys.nix`); os atalhos `honeyctl toggle ...`, `lock` e `screenshot` estão repetidos nos 3 arquivos (formatos diferentes) e precisam ser sincronizados à mão.
  - **Cores/tema**: âmbar espalhado em `honey.nix`, `pleamar.nix` (substituições no `session.plm`), `niri.nix` (`focus-ring`) e `hyprland.nix` (`col.active_border`). O tema do shell vem da config do Honey (seção 4).
  - **Monitor**: DP-1 `1920x1080@165.003`, escala 1.25, nos perfis de compositor. O valor precisa bater exatamente com o modo, senão o niri cai para 60 Hz. No COSMIC isso se ajusta em Configurações e fica em `~/.config/cosmic/`.
- Gotchas:
  - `honey.nix` fixa kitty e nautilus e ignora `geko.desktop.terminal` e `fileManager`. Só o Serpantinum consome essas options.
  - `serpantinum.nix` e `hyprland.nix` definem ambos `programs.hyprland`. Nunca importar os dois juntos.
  - No Hyprland Honey: `package=null`, `systemd.enable=false`, e `honeyctl session` sobe o ambiente.
  - No niri o shell roda com `PLEAMAR_NO_LENS=1` (bug de captura) e há o loop `honey-niri-outputs`.
  - O pleamar precisa de `xdg.portal.config.pleamar`, senão o diálogo de arquivo não abre.
  - Mover o repo quebra `programs.nh.flake` e o autoUpgrade (caminho fixo).

## 4. Honey shell (`pkgs/honey-shell/`, `S` = `source/`)

Shell de desktop (launcher, clipboard, controles, tray, power, relógio; o corpo dança com o cava) para o runtime Pleamar. Documentação: `docs/honey.md`.

- Processos:
  - `honey-shell` (bash que executa `pleamar --scene src/honey.plm --no-hud --stall 0`) e `honey-reserve` (surface de 1 px que reserva 80 px).
  - `services/bridge.py stream`: filho do pleamar, que ele inicia via `spawn` no Luau. Inicia `cava` e `wl-paste --watch`.
  - `honeyctl` (`S/cli.py`): CLI chamada por atalhos e compositor.
- Módulos Python:
  - `cli.py`: `PANELS` (launcher=10, files=11, commands=12, settings=13, emoji=14, clipboard=15, controls=2, tray=3, power=4, close=0). `toggle`/`open` rodam `pleamar --say honey 'emit control N'`. Também `lock`, `suspend`, `screenshot`, `session`, `media`.
  - `core/config.py`: `DEFAULTS`, `merge`, `validate`, `Store` (mantém a última config válida, recusa escrita quando managed), `palette()` e `write_palette` (gera `themes/active.plm`, mexe no `rim` de `material.plm` e no `reserve` de `reserve.plm`, com rollback se `pleamar --check` falhar).
  - `services/bridge.py`: `search`, `execute`, `action`, `snapshot`, `capture` (histórico de até 100 itens), `stream`, `ddc_read`/`ddc_set`.
  - `services/app_scope.py`: embrulha `setsid -f sh -c CMD` em `systemd-run --user --collect --property=PartOf=graphical-session.target` para que reiniciar o Honey não mate os apps. Depende do formato exato do Pleamar 0.2.8.
  - `adapters/compositor.py`: `detect`, `power_command`, `capabilities`.
- Protocolo: sem socket próprio. NDJSON em stdout do `bridge.py stream`, com `type` igual a `config`, `cava`, `brightness` ou `clipboard`. Chamadas pontuais: `bridge.py <snapshot|search|action|prepare> '<json>'`, que devolve um JSON (`generation` descarta buscas antigas).
- Config: `DEFAULTS` → `presets/Honey.json` → `config/user.json` (ou `$HONEY_CONFIG`). No Nix, `programs.honeyShell.settings` sobrescreve o `user.json` no build e `HONEY_MANAGED=1` deixa tudo read-only. `mode=demo` simula tudo (dev), `live` é o real.
- Empacotamento (`default.nix`): valida no build (`bridge.py prepare` com `HONEY_BUILD=1`, `pleamar --check`), gera `wallpaper.png`, cria wrappers `honeyctl`, `honey-shell` e `libexec/honey-apps/setsid`.
- Testes (`S/tests/`): `test_helpers`, `test_managed`, `test_recovery`, `test_app_scope`, `test_ddc_queue` (precisa de `luau` ou `HONEY_LUAU`). `controls_renderer.py` e `tray_renderer.py` são scripts manuais. Integração em `tests/honey-vm.nix`.
- Gotchas:
  - `honeyctl` exige `PLEAMAR_SOCKETS` não definido.
  - Em NVIDIA o ddcutil trava frames (cache de bus, retry de 120 s, polling de 60 s, debounce de 80 ms).
  - Estilo Python denso: preserve a lógica de last-good e os caminhos confinados (`is_relative_to`).
  - Pendente: não foi testado em hardware NVIDIA real. A refração está desligada no niri.

## 5. Honey UI (pleamar)

- Pleamar 0.2.8, `language 0.2`. `.plm` é a cena declarativa (desenho, springs, zonas, regras). `.luau` é a lógica, sandboxed, só publica fatos e não conhece coordenadas. `pleamar-wm` é o WM e é ele mesmo uma cena. Rode sempre `pleamar --check x.plm`. A doc do executável (`pleamar --docs ...`) prevalece sobre a skill.
- Cena única `S/src/honey.plm` (surface `main` em tela cheia, pass-through quando ociosa). Painel aberto = `fact panel`: 0 idle, 1 launcher, 2 controls, 3 tray, 4 power, 6 wallpapers, 7 notificações (o 5, cava, não existe mais).
- Layout em notch: `ctlx`/`centralx`/`trpx`/`rightx` são ancorados à gota central (`notchgap`), não às bordas da tela. `groove` (mola) segue `fact.beat * grooveamt`; `volosdv` segue `fact.volosd` (indicador de volume externo, `audio_changed` em `honey.luau`).

| Arquivo | Papel |
|---|---|
| `src/honey.plm` | layout, springs, launcher, relógio, zonas, teclas |
| `src/honey.luau` (510 linhas) | máquina de estados dos painéis, busca, tray, ações, `spawn` do bridge, `sys.watch/call` |
| `components/material.plm` | vidro/mel (`Honey(x,w,h,motion,fused)`) |
| `components/controls.plm` | sliders de volume e brilho, mute |
| `components/tray.plm` | Wi-Fi/BT, ícones, menu DBus |
| `components/power.plm` | 5 ações, com confirmação em 2 cliques para reboot e shutdown |
| `components/result.plm` | linha do launcher |
| `components/wallpapers.plm` | colmeia de wallpapers (`HexWall` em `material.plm`), painel 6 |
| `components/notifications.plm` | gotas de notificação (`NoteToasts`) e central (`NotePanel`, painel 7); as formas ficam no `HoneyTop` |
| `reserve.plm`, `preview-background.*`, `capture-probe.plm` | reserva do topo, fundo do preview, diagnóstico |
| `shaders/meniscus.wgsl`, `capture-probe.wgsl` | shaders |

- Tema: `src/themes/active.plm` é GERADO por `palette()` em `S/core/config.py`. Não editar. Mude `config/user.json`, `presets/Honey.json`, `programs.honeyShell.settings` ou `palette()`.
- Docs (`docs/pleamar/`): `SKILL.md` (comece aqui), `grammar.txt` (vocabulário exato), `reference.md` (1463 linhas, use grep: §6 declarações, §8 desenho/shaders, §10 componentes, §13 regras, §15 gestos), `logic.md` (limites do Luau), `measuring.md` (CPU). `docs/updates-and-claude.md` NÃO é de UI: é sobre o autoUpgrade e o Claude.
- Regras de sintaxe:
  - Nunca chute palavras: confira em `grammar.txt`.
  - Intervalos são exclusivos no fim (`0..6` vai de 0 a 5).
  - O press vai para a zona declarada POR ÚLTIMO (por isso `zone box outside` vem primeiro).
  - Não escreva em `prop ~spring` por frame no Luau (use `follow`, regras ou `impulse`).
  - Todo `event` que o Luau escuta precisa de seta (`event nome ->`).
  - `sys.call` novo exige `permissions` em `honey.plm` e, se usar `run`, o comando em `run:`.
  - `model` tem `max` fixo (`hits max 7` = `fact.capacity`; `traymini` e `icons` têm `max 5`).
  - Em sliders, mantenha `pointer.x` inline.
  - Posições dependem de `centralx`/`centralw` (o notch) e de `compact` (ww < 1400). `sidex`, `trayx` e `rightx` são derivados da gota central.
  - Texto em pt-BR. Fontes: `family: "Nunito"` no texto de UI (peso 600 em texto pequeno) e `family: "Fredoka"` só em títulos e nos dígitos do relógio (um dígito por `text`, dígitos proporcionais). `family:` só aceita string literal (não aceita `let`), e nome errado não falha no `--check`: `tests/test_fonts.py` cobre isso. As fontes vêm de `desktops/_comum-honey.nix`.
- Onde editar:
  - **bar/relógio**: `honey.plm`.
  - **launcher**: `honey.plm`, `result.plm` e as funções `search`/`activate` em `honey.luau`.
  - **controls**: `controls.plm` e `on("volume_set"|"brightness_set"|"mute")`.
  - **tray**: `tray.plm` e `tray_rows`/`on("tray_*")`.
  - **power**: `power.plm` e `on("power_action")`.
  - **dança com a música**: `fact.beat` no handler `cava` de `honey.luau`, mola `groove` em `honey.plm`, `g` e `sway` no `HoneyTop`; leitura em `stream()` de `bridge.py`.
  - **novo painel**: `event`/`prop` em `honey.plm`, um componente novo, `request(N)` em `honey.luau` (limite `which > 5`) e um `fact xxxon`.

## Regra de teste do shell

Antes de carregar um shell novo (`pleamar --scene ...`), mate o antigo: `systemctl --user stop honey-shell.service` e `pkill -f 'bin/pleamar --scene' || true` (o processo aparece com o caminho completo do Nix, então `^pleamar` não casa). Dois shells sobrepostos falseiam capturas e medições. Ao terminar, `systemctl --user start honey-shell.service`. Medir custo: `pleamar --scene src/honey.plm --seconds 9 --no-hud --no-vsync` e olhar a linha `cycle` (meta: frame médio abaixo de ~1 ms, `reading the scene` perto de 0,1 ms). Nunca use `path` fechado no material (custa ~12 ms por frame).

## 6. Estado atual e pendências conhecidas

- Não commitado: `flake.nix` (input `claude-desktop-app`, `desktopProfile`), `modules/core` (autoUpgrade), `desktops/pleamar.nix` (mapa de portais), modo `@165.003` nos home Honey, `pkgs/honey-shell/**` (com testes novos), `programs/`, `flake.lock`, `docs/updates-and-claude.md` (untracked).
- `reference.md` (cabeçalho "version 0.1") está defasado. README e guias de programas foram atualizados nesta migração.
- Estrutura reorganizada na branch `refactor/estrutura-iniciante` (pasta `desktops/`, opção `geko.usuario.nome`).
- Existem symlinks `result*` na raiz (artefatos de build, não editar).
