# geko-nix

Configuração pessoal do geko: NixOS, Hyprland e Serpantinum. O alvo `nixos`
e o alias `nixos-serpantinum` constroem o mesmo sistema. O perfil
`nixos-pleamar` usa Pleamar-WM + Marea como desktop separado. Ryoku, XFCE e Hermes
foram removidos das declarações; dados pessoais não são apagados.

## Organização

- `configuration.nix`: identidade, pt-BR, São Paulo e serviços da máquina.
- `hardware-configuration.nix`: discos/swap existentes, sem alterações.
- `modules/core/`: ferramentas e serviços comuns, inspirados no OrbitOS, sem Orbit CLI.
- `modules/hardware/nvidia-desktop.nix`: NVIDIA aberto, KMS e aceleração de vídeo.
- `modules/desktop/serpantinum.nix`: compositor, shell e integração da sessão.
- `modules/desktop/options.nix`: componentes substituíveis por opções `geko.desktop`.
- `modules/desktop/gaming.nix`: seleção de launchers, ferramentas e controles.
- `modules/services/docker.nix`: Engine, Compose e utilitários; sem stacks automáticas.
- `programs/`: apps estáveis/unstable, desenvolvimento, faculdade e Proton.
- `home/`: Home Manager, Fish e AstroNvim.
- `config/`: Fish/Starship e atalhos Lua do Hyprland.
- `pkgs/sqldeveloper.nix`: pacote Oracle com fonte/hash fixados e JDK 17 próprio.

O Serpantinum e o compositor usam a revisão testada na VM. O restante do
sistema conserva os inputs stable/unstable existentes. Atualizações são
explícitas pelo lock; não há atualização automática do sistema.

## Componentes

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
`withMarea = true`; ele não importa Hyprland nem Serpantinum. Configurações
do Pleamar permanecem em `~/.config/pleamar` segundo o upstream.
Para construir esse perfil: `nix build .#nixosConfigurations.nixos-pleamar.config.system.build.toplevel`. As configurações Lua do Hyprland
são declarativas: editar pela interface não altera o arquivo gerado pelo HM.
As preferências do Serpantinum são inicialmente semeadas pelo módulo upstream,
mas depois permanecem editáveis na interface; o rebuild não sobrescreve um
`settings.json` já existente.

## Construção

```sh
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

Construir não ativa a configuração. Nenhuma ativação é feita por este projeto.
Depois de revisar a geração, a ativação exige uma ação separada do usuário.
O HM faz backup de arquivos conflitantes com o sufixo `before-geko-nix`;
um backup com o mesmo nome já existente pode impedir a ativação.

Docker usa o grupo `docker` (poder equivalente a administrador). O módulo
herdado do Orbit remove semanalmente imagens Docker não utilizadas. Java usa
JDK 21; SQL Developer usa seu JDK 17 isolado. NetBeans vem do input estável.
Jogos, NVIDIA, som e Docker em execução exigem teste após ativação no hardware.

## Origem

Fish, Starship, core, NVIDIA, Docker e a estrutura gaming foram adaptados de
[OrbitOS](https://github.com/Orbit-Nix/orbit-config). O shell é
[Serpantinum](https://github.com/ilyamiro/serpantinum), preservando a licença
AGPL do upstream; fontes e licenças dos projetos originais continuam aplicáveis.
Não versione tokens, hashes de senha ou estados privados de aplicativos.
