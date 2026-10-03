# Honey · três perfis declarativos

Os perfis `pleamar`, `niri` e `hyprland` usam o mesmo shell Honey. `nixos` e `serpantinum` continuam com Serpantinum. Os builds não ativam nenhum deles.

## Onde configurar

`home/desktop/honey.nix` define o módulo `programs.honeyShell` e os padrões comuns. Os módulos irmãos definem compositor, entrada, atalhos e aparência. Os registros de sessão, PAM e portais ficam em `modules/desktop/`.

Exemplo de preferências declarativas:

```nix
programs.honeyShell.settings = {
  motion.reduced = true;
  modules.cava = false;
  appearance.base = "#b97912";
  files.roots = [ "~/Documentos" "~/Downloads" "~/Imagens" ];
};
```

As preferências são mescladas com os padrões e o preset Honey; configuração inválida rejeita o build. O painel Ajustes só informa os valores e a origem Home Manager. Não escreve preferências.

Código, tema e configuração são imutáveis. O histórico vai para `$XDG_STATE_HOME/honey/history.json` (até 100 entradas), imagens para a subpasta clipboard e temporários para `$XDG_CACHE_HOME/honey`. O launcher permite limpar o histórico; também existe `honeyctl clear-clipboard`.

## Atalhos

| Atalho | Ação |
|---|---|
| Super+Space / Super+D | Launcher |
| Super+V | Clipboard |
| Super+comma | Ajustes |
| Super+Return | Kitty |
| Super+E | Nautilus |
| Super+Q | Fechar janela |
| Super+F | Fullscreen |
| Super+Shift+F | Flutuante |
| Super+setas / Super+Shift+setas | Foco / mover |
| Super+1…9 / Super+Shift+1…9 | Workspace / enviar |
| Super+L | Swaylock |
| Super+Shift+E | Power |
| Print / Shift+Print | Captura de região / tela |

No Pleamar-wm, Super+Tab abre overview e Super+Ctrl+F alterna o monitor livre. No Niri, Super+Tab abre overview. Teclas de áudio e brilho chamam `honeyctl media`; áudio é limitado a 100%. DDC/CI descobre o barramento, sem número fixo. Ausência de suporte é informada.

## Sessão

`honeyctl session` importa o ambiente gráfico, inicia `honey-session.target` uma única vez e observa a vida do socket Wayland. Quando o compositor termina, encerra o target e seus serviços. Honey, reserva superior, wallpaper, Mako, polkit e o hook de bloqueio antes de suspender pertencem ao target. O helper Honey observa clipboard e Cava; seus filhos pertencem ao grupo do serviço.

Não há timers de idle. Suspensão pelo painel exige bloqueio bem sucedido primeiro. Reboot e shutdown exigem confirmação dentro do painel. Swaylock usa PAM do NixOS; o Honey não implementa autenticação própria.

O catálogo e a validação de aplicativos continuam no serviço oficial `apps.launch`. O pacote intercepta sua chamada `setsid -f sh -c` e inicia o aplicativo em um serviço transitório separado pelo systemd. `setsid` sozinho não sai do grupo de processos do serviço: reiniciar Honey encerrava auxiliares de aplicativos Electron, incluindo o GPT. Agora aplicativos pertencem à sessão gráfica, e reiniciar o shell só encerra seus próprios helpers. Outras chamadas de `setsid` usam o binário original.

## Compatibilidade visual

A reserva superior usa uma superfície transparente de 1 pixel em `honey-reserve.service`, ancorada apenas ao topo, com zona exclusiva de 80 pixels lógicos. A superfície principal ignora zonas exclusivas para manter o mel na origem da tela. Uma superfície de altura total ancora ambas as bordas verticais; sua reserva seria ignorada pelos compositores.

No Niri, o runtime Pleamar fixado solicita um buffer ARGB após receber a indicação de XRGB. O compositor rejeita esse buffer e desconecta o cliente. O perfil usa o fallback oficial `PLEAMAR_NO_LENS=1`: mel translúcido e highlights, sem captura/refração do fundo. Não há imagem falsa de refração.

O pacote Pleamar-wm inclui uma correção local para buffers lineares XRGB: quando o driver rejeita o registro com modificadores, usa o registro DRM legado. A alteração preserva o caminho dos buffers não lineares e não muda layouts ou springs. O check estrito da VM passou com captura nativa; o hardware NVIDIA ainda precisa de teste próprio. A correção está em `pkgs/pleamar-linear-framebuffer.patch`.

O perfil Niri acompanha monitores conectados e aplica modo preferido/escala 1 às saídas diferentes de DP-1. DP-1 mantém sua configuração explícita. O observador termina com a sessão.

O teste de VM do Niri usa Weston como compositor auxiliar, porque o backend DRM do Niri rejeita o renderizador por software do QEMU. A sessão instalada continua sendo Niri diretamente. Resultados desse teste não comprovam o backend DRM/NVIDIA físico.

## Construir e validar

```sh
nix build --no-link .#nixosConfigurations.pleamar.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.niri.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.hyprland.config.system.build.toplevel
nix build --no-link .#checks.x86_64-linux.honey-pleamar
# Check diagnóstico adicional da sessão Pleamar:
nix build --no-link .#checks.x86_64-linux.honey-pleamar-core
nix build --no-link .#checks.x86_64-linux.honey-niri
nix build --no-link .#checks.x86_64-linux.honey-hyprland
```

Os checks usam máquinas virtuais com usuário e senha de teste, sem acesso às contas ou dispositivos físicos. Sucesso do build não comprova suporte da GPU NVIDIA, DDC/CI, suspensão ou áudio físicos.

## Ativação futura · não executada nesta entrega

Depois de revisar os resultados e sair da sessão gráfica atual, escolha **um** perfil e aplique-o na sua própria sessão administrativa:

```sh
sudo nixos-rebuild switch --flake /home/geko/Documentos/geko-nix#pleamar
# Alternativas: #niri ou #hyprland
```

Faça login na sessão correspondente no SDDM. O backup Home Manager usa a extensão `.before-geko-nix`; arquivos locais existentes não devem ser apagados manualmente para contornar conflitos.

Para voltar à configuração anterior, use `#nixos` ou a geração anterior no boot. Nunca execute o script de ativação Home Manager separado enquanto estiver usando outro perfil: ele troca os mesmos arquivos de configuração do usuário.

Settings completo, notificações nativas, media player, IA, wallpaper picker, overview Honey e lock screen próprio continuam para etapas posteriores.
