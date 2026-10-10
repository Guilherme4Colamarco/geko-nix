# Programas organizados por uso

[Equivalent English guide](software.md).

Edite **`programs/user.nix`**. Todos os pacotes do Nixpkgs usam a revisão
fixada de `nixos-unstable`; flakes externos, SQL Developer e Protons próprios
conservam suas revisões e hashes. Não há divisão de aplicativos stable/unstable.

## Configuração inicial

Este exemplo é um ponto de partida, não a seleção pessoal do geko:

```nix
{ pkgs, ... }: {
  software = {
    user.packages = with pkgs; [ brave-origin obsidian ];
    flatpak.packages = [ "com.stremio.Stremio" ];
    gaming = {
      enable = true;
      apps = [ "steam" "heroic" "prism" "mangohud" ];
      controllers.enable = false;
      optimizations.enable = false;
      steam.remotePlay.enable = false;
      steam.dedicatedServer.enable = false;
      proton = [ "ge" ];
    };
    office.enable = false;
    development = {
      enable = true;
      apps = [ "neovim" "nodejs" "python" "build-tools" ];
      docker.enable = false;
    };
    studio.enable = false;
  };
}
```

Todas as categorias têm `enable = false` por padrão. Habilitar sem definir
`apps` usa o conjunto inicial da tabela abaixo. Uma lista explícita substitui
esse conjunto; `apps = []` permite usar apenas integrações ou `extraPackages`.
Seleções repetidas são resolvidas uma vez. Nomes desconhecidos falham na
avaliação e mostram os valores aceitos. Pacotes não selecionados não são
avaliados nem instalam dependências.

`software.user.packages` apenas instala pacotes pelo Home Manager, sem
configurá-los. Por exemplo, incluir `pkgs.neovim` não habilita a configuração
do editor oferecida pela categoria. Cada categoria aceita também
`extraPackages = with pkgs; [ hello ];`, instalado somente com a categoria
ligada. Listas de diferentes módulos Nix são combinadas; use `lib.mkForce`
para substituir deliberadamente a lista explícita de outro módulo. Na edição
normal, basta substituir a lista em `user.nix`.

## Catálogo

Os nomes abaixo são as strings literais usadas em `apps`.

| Categoria | Conjunto inicial | Seleções adicionais |
|---|---|---|
| Gaming | `steam`, `heroic`, `prism`, `mangohud` | `hydra`, `lutris`, `bottles`, `itch`, `sober`, `roblox` (alias de Sober), `lunar`, `bedrock`, `modrinth`, `atlauncher`, `gdlauncher`, `badlion`, `pcsx2`, `rpcs3`, `dolphin`, `retroarch`, `ppsspp`, `dualsensectl`, `protonup-qt`, `protontricks`, `goverlay` |
| Office | `libreoffice`, `evince`, `thunderbird` | `onlyoffice`, `obsidian`, `zotero` |
| Development | `neovim`, `gh`, `nodejs`, `python`, `build-tools`, `nix-tools`, `direnv` | `vscodium`, `cursor`, `antigravity-ide`, `antigravity-cli`, `codex`, `claude-code`, `jdk21`, `netbeans`, `sqldeveloper`, `dbeaver`, `go`, `rust` |
| Studio | `krita`, `inkscape`, `kdenlive`, `obs-studio`, `audacity`, `blender` | `gimp`, `darktable`, `shotcut`, `ardour` |

As entradas antigas de gaming foram avaliadas individualmente no lock existente.
`minecraft` foi removido do Nixpkgs por estar quebrado (use `prism`). `ryujinx`
foi removido em favor do upstream `ryubing`, que não integra este catálogo.
Essas duas entradas não são aceitas; `allowBroken` não foi habilitado.
As demais passaram na avaliação da derivação, não em testes de execução.

## Integrações e dependências

- **Gaming:** `steam` habilita o módulo NixOS do Steam, sem uma segunda cópia
  no perfil pessoal. `proton` usa `[ "ge" ]` por padrão; `dw` e `cachyos`
  mantêm as versões e hashes de `programs/proton.nix`. `[]` desliga os
  Protons extras. Protons e portas do Steam só se aplicam quando ele está
  selecionado. `controllers.enable` habilita xone, xpadneo e regras udev
  do DualSense. `optimizations.enable` habilita GameMode e Gamescope, mais
  a sessão Gamescope do Steam quando selecionado. Esses switches e os dois
  switches de firewall são desligados por padrão. Desligar gaming desliga
  todas essas integrações. Drivers de vídeo permanecem independentes em
  `modules/hardware/`.
- **Development:** `python` inclui Python e uv; `nodejs` inclui npm;
  `build-tools` instala GCC, Make, CMake, Ninja e pkg-config; `nix-tools`
  instala nixd, nixfmt, ShellCheck e shfmt. `direnv` habilita integração
  com os shells pelo Home Manager e nix-direnv. `rust` usa rustc e Cargo
  do Nixpkgs, sem rustup. `jdk21` habilita Java no NixOS com JDK 21; SQL
  Developer tem seu próprio JDK 17. Neovim é configurado pelo Home Manager
  e passa a ser o editor do usuário.
- **Docker:** `development.docker.enable` exige development habilitado.
  Liga o Docker Engine, grupo Docker, Compose, lazydocker e ctop. O grupo
  dá acesso equivalente a administrador. A limpeza semanal existente de
  imagens não utilizadas (`--all`) e as configurações de logs foram
  preservadas; a categoria não declara nem inicia containers ou stacks.
- **Studio:** OBS usa o Home Manager com `obs-pipewire-audio-capture`, sem
  instalar outra cópia do OBS pela categoria. Kdenlive, OBS, Audacity,
  Blender, Shotcut e Ardour também acrescentam FFmpeg.
- **Office:** integração normal com o desktop; não impõe contas,
  associações de arquivos ou idioma.

## Flatpaks e configurações pessoais

`software.flatpak.packages` recebe IDs do Flathub. Sober/Roblox e Modrinth
acrescentam seus IDs automaticamente. `programs/flatpak.nix` remove repetições
da lista combinada e habilita Flatpak somente se ela não estiver vazia.
O módulo NixOS mantém a **instalação de sistema** existente; os atalhos de
terminal usam esse Flatpak. `uninstallUnmanaged = false` e
`uninstallUnused = false` preservam aplicativos e repositórios manuais.
Remover uma seleção não apaga seus dados nem desinstala um Flatpak existente.
Listas vazias desligam o suporte gerenciado, sem apagar a instalação.
A instalação de Flatpaks ocorre na ativação e precisa de rede; um build Nix
não baixa nem testa esses aplicativos. Veja o
[comportamento do nix-flatpak](https://github.com/gmodena/nix-flatpak/blob/main/README.md).

A seleção explícita do geko preserva Docker, drivers de controles, otimizações,
as duas integrações de firewall do Steam e os três Protons. Office e studio
começam desligados; Obsidian e FFmpeg ficam na lista pessoal. AstroNvim e
skills do Claude Code são importados por `programs/user.nix` e condicionados
às respectivas seleções de development. Não são padrões das categorias para
outra pessoa. Claude Desktop e a integração KVM do Cowork também continuam
pessoais. Identidade, idioma, teclado e discos permanecem iguais.
Componentes necessários à sessão (chaveiro, brilho, GPU e dependências dos
compositores) ficam fora das categorias opcionais.

## Editar, verificar, aplicar e voltar atrás

```sh
# Edite programs/user.nix; exponha arquivos NOVOS ao flake, se houver:
git add -N caminho/do/novo-modulo.nix
nix build --no-link .#checks.x86_64-linux.software .#checks.x86_64-linux.software-personal --no-update-lock-file
nix build .#nixosConfigurations.serpantinum.config.system.build.toplevel \
  --no-update-lock-file --out-link result-software
# Ative exatamente a geração que acabou de construir:
sudo ./result-software/bin/switch-to-configuration test
sudo nix-env --profile /nix/var/nix/profiles/system --set "$(readlink -f result-software)"
sudo ./result-software/bin/switch-to-configuration switch
# Se necessário, retorne à geração de sistema anterior:
sudo nixos-rebuild switch --rollback
```

Troque `serpantinum` por `nixos`, `niri`, `hyprland` ou `pleamar` conforme o caso.
Construir não ativa. `test` muda a sessão em execução, mas não o padrão de boot.
`switch` registra a geração para os próximos boots. O rollback restaura o
sistema declarado anterior, não dados mutáveis dos aplicativos nem versões
de Flatpaks. O sufixo de backup do Home Manager é `before-geko-nix`; um backup
conflitante existente pode bloquear a ativação. Não apague dados pessoais
para resolver o conflito. Não atualize `flake.lock` nesta refatoração;
atualizações dos canais são uma operação separada.

O check `software` cobre categorias desligadas, isoladas, juntas, seleções
vazias, repetidas e inválidas, integrações opcionais, união de Flatpaks e a
derivação de cada entrada do catálogo. Veja a
[verificação da migração](software-validation.md) para os perfis e a comparação
antes/depois da seleção pessoal.

## Mapa dos módulos

`programs/default.nix` importa `user.nix`, `flatpak.nix` e as quatro categorias.
`category.nix` define suas opções comuns; `proton.nix` guarda versões fixadas.
`modules/services/docker.nix` é importado por development e condicionado aos
seus switches. Para reutilizar sem escolhas pessoais, use
`disabledModules = [ ./programs/user.nix ];` (ajuste o caminho ao seu arquivo)
e forneça suas próprias definições de `software`. O namespace antigo
`mySystem.gaming` e os módulos stable/unstable/faculdade deixaram de existir.
Novas entradas devem ser incluídas no catálogo da categoria e nos dois guias.
