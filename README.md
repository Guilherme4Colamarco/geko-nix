# geko-nix

Configuração pessoal do geko: NixOS, Hyprland e Serpantinum. O alvo `nixos`
e o alias `serpantinum` constroem o mesmo sistema. O perfil
`pleamar` usa Pleamar-WM + Honey como desktop separado. O perfil `cosmic`
é o desktop COSMIC do nixpkgs, com login próprio e sem Honey. Ryoku, XFCE e Hermes
foram removidos das declarações; dados pessoais não são apagados.

## Organização

- `configuration.nix`: identidade, pt-BR, São Paulo e serviços da máquina.
- `hardware-configuration.nix`: discos/swap existentes, sem alterações.
- `modules/core/`: ferramentas e serviços comuns, inspirados no OrbitOS, sem Orbit CLI.
- `modules/hardware/nvidia-desktop.nix`: NVIDIA aberto, KMS e aceleração de vídeo.
- `desktops/`: perfis Serpantinum, Pleamar, Niri, Hyprland e COSMIC; compositor e sessão.
- `modules/desktop/options.nix`: componentes substituíveis por opções `geko.desktop`.
- `programs/user.nix`: pacotes pessoais, Flatpaks e categorias opcionais.
- `modules/services/docker.nix`: Engine, Compose e utilitários; sem stacks automáticas.
- `programs/`: gaming, office, development e studio; catálogo e integrações.
- `home/`: Home Manager, Fish e AstroNvim.
- `config/`: Fish/Starship e atalhos Lua do Hyprland.
- `pkgs/sqldeveloper.nix`: pacote Oracle com fonte/hash fixados e JDK 17 próprio.

A base do sistema, os aplicativos e os compositores do Nixpkgs usam
`nixos-unstable`; o Home Manager acompanha `master`. `nixpkgs-unstable` é um
alias do input principal, sem uma segunda versão de pacotes. Os flakes externos
(como Serpantinum e Pleamar) mantêm suas revisões e dependências próprias.
`system.stateVersion` e `home.stateVersion` preservam a compatibilidade dos dados.
O `flake.lock` fixa as revisões. A atualização automática roda às 04:40, com
atraso aleatório de até 20 minutos, e prepara a geração para o próximo boot,
sem reiniciar a máquina. Para atualizar manualmente os canais da base:

```sh
nix flake update nixpkgs home-manager
```

## Programas por uso / Software by use

Edite [`programs/user.nix`](programs/user.nix): `software.user.packages`,
`software.flatpak.packages` e as categorias `gaming`, `office`, `development`
e `studio`. Categorias são desligadas por padrão; esta máquina declara suas
escolhas atuais explicitamente. `apps` substitui o conjunto inicial e
`extraPackages` acrescenta pacotes. Aplicativos comuns usam Home Manager;
serviços, drivers e integrações continuam no NixOS.

- [Guia em português: catálogo, exemplos, aplicação e rollback](docs/software.pt-BR.md)
- [English guide: catalog, examples, activation and rollback](docs/software.md)
- [Verificação da migração / Migration verification](docs/software-validation.md)

## Componentes

A aparência dos aplicativos GTK é declarada em `home/gtk.nix`, comum a todos
os perfis. `gtk.theme.package` instala o tema e `gtk.theme.name` seleciona o
nome fornecido pelo pacote; `gtk.iconTheme`, `gtk.font` e `gtk.cursorTheme`
controlam ícones, fonte e cursor. `gtk.colorScheme` escolhe `"dark"` ou `"light"`.
GTK 4/libadwaita recebe a preferência de cor sem importar o CSS de GTK 3.
Após editar, aplique com `nh os switch -H serpantinum` (ou seu perfil atual)
e reabra os aplicativos. Alterações manuais nessas preferências podem ser
substituídas na próxima ativação do Home Manager.

Em um módulo NixOS, por exemplo:

```nix
{ pkgs, ... }: {
  geko.desktop.terminal = pkgs.kitty;
  geko.desktop.fileManager = pkgs.nautilus;
  geko.desktop.clipboard.enable = true;
}
```

Novos desktops podem ter módulos próprios e outputs na mesma flake, usando
os módulos comuns. Não há perfil Ryoku. O perfil Pleamar usa o módulo upstream com
`withMarea = false`; ele não importa Hyprland nem Serpantinum. Configurações
do Pleamar permanecem em `~/.config/pleamar` segundo o upstream.
O perfil COSMIC (`nh os switch -H cosmic`) usa o módulo do nixpkgs, desliga o SDDM
e entra pelo cosmic-greeter. Painel, tema e monitor ficam em `~/.config/cosmic/`.
Para construir esse perfil: `nix build .#nixosConfigurations.pleamar.config.system.build.toplevel`. As configurações Lua do Hyprland
são declarativas: editar pela interface não altera o arquivo gerado pelo HM.
As preferências do Serpantinum são inicialmente semeadas pelo módulo upstream,
mas depois permanecem editáveis na interface; o rebuild não sobrescreve um
`settings.json` já existente.

## Construção

```sh
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

Construir não ativa a configuração. Para testar e aplicar exatamente a geração
construída, siga o guia de programas abaixo.
O HM faz backup de arquivos conflitantes com o sufixo `before-geko-nix`;
um backup com o mesmo nome já existente pode impedir a ativação.

Docker usa o grupo `docker` (poder equivalente a administrador). O módulo
herdado do Orbit remove semanalmente imagens Docker não utilizadas. Java usa
JDK 21; SQL Developer usa seu JDK 17 isolado. NetBeans vem do input unstable.
Jogos, NVIDIA, som e Docker em execução exigem teste após ativação no hardware.

## Origem

Fish, Starship, core, NVIDIA, Docker e a estrutura gaming foram adaptados de
[OrbitOS](https://github.com/Orbit-Nix/orbit-config). O shell é
[Serpantinum](https://github.com/ilyamiro/serpantinum), preservando a licença
AGPL do upstream; fontes e licenças dos projetos originais continuam aplicáveis.
Não versione tokens, hashes de senha ou estados privados de aplicativos.
