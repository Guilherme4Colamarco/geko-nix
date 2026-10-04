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

## Forma do mel

O corpo (`components/material.plm`, componente `Honey`) é uma caixa com seis caroços de tamanhos diferentes fundidos à borda inferior; eles derivam com `noise(..., time)` e dão o contorno irregular que respira. Não há gotas soltas. O movimento contínuo escala com o token `life` (`motion.life`, 0 a 2, padrão 1); `motion.reduced` zera `life` e `deform`, e o mel fica estático. A opacidade padrão do mel é 0,66 (`appearance.opacity`). Botões, linhas e campo de busca usam `Gob` (pílula com dois caroços, sem vidro, para não empilhar refração); os sliders usam `Fluid`, cuja gota final segue o valor por mola viscosa e estica com a velocidade; as barras do Cava são elipses fundidas. Não use `path` aqui: um `path` fechado custou cerca de 12 ms de leitura de cena por frame com o launcher aberto (contra 0,1 ms com elipses), e o shell ficava lento. Limitações do Pleamar 0.2.8: `children` e `repeat` não valem dentro de `body`, então cada painel continua sendo um corpo separado, e `rim` só aceita porcentagem literal (por isso `write_palette` ainda a reescreve). Todos os tokens do material (`life`, `dispersion`, `dome`, `ripple`, molas `blob` e `drip`) vêm de `palette()` em `core/config.py`.

## Wallpapers

`honeyctl toggle wallpapers` (Super+Shift+W nos três perfis) abre a colmeia: a gota central cresce e mostra 12 imagens por página como hexágonos de mel (três caixas rotacionadas; a miniatura é recortada por três `clip` em faixa aninhados). No hover o hexágono pinga; ao escolher, ele cede, escorre e o painel fecha. A pasta vem de `wallpaper.folder` (padrão `~/Imagens/Wallpapers`; png, jpg, jpeg e webp) e o ajuste de `wallpaper.fit` (`fill`, `fit`, `center`, `tile`, `stretch`), ambos em `programs.honeyShell.settings`. A escolha fica em `$XDG_STATE_HOME/honey/wallpaper.json`; `honey-wallpaper.service` roda `honeyctl wallpaper-run`, que usa essa imagem ou cai no wallpaper do pacote. Em demo só as imagens de `fixtures/` aparecem e nada é aplicado. `modules.wallpaper = false` desliga o painel.

## Tipografia

Nunito no texto de UI (peso 600 em texto pequeno, +1 px sobre a DejaVu por causa do x-height menor) e Fredoka nos títulos e nos dígitos do relógio. O pleamar só repassa `family` e `weight`: não há `tnum`, e `family:` só aceita string literal (não aceita `let`), então os nomes estão escritos em cada `text` e `tests/test_fonts.py` falha se algum nome estiver errado, já que um nome errado cai em silêncio no fallback. Como os dígitos da Fredoka são proporcionais, o relógio é montado com um `text` por dígito, cada um centralizado numa célula fixa (`clockcell`); se algum dígito encostar no vizinho, aumente a célula. As fontes vêm de `modules/desktop/honey-common.nix` (`pkgs.nunito` e `google-fonts` só com a Fredoka) e `fonts.fontconfig.defaultFonts.sansSerif` passa a ser Nunito, o que alcança GTK, Qt, o niri (pango "sans") e o mako. Hyprland usa `misc.font_family`, swaylock e mako têm `font=`, e o texto do pleamar-wm recebe `family: "Nunito"` por `sed` na cena (ele ignora o fontconfig padrão). Depois de aplicar, reinicie o `honey-shell`: o pleamar lê a lista de fontes só na partida.

## Notificações

O pleamar é o servidor `org.freedesktop.Notifications` (serviço `notifications`); o mako não é mais iniciado. Cada notificação é uma gota que desce da faixa do topo, no mesmo corpo de mel do `HoneyTop` (até `notifications.max_visible`, 3). Urgência: `low` some em `notifications.low_timeout` s e é mais fina; `normal` some em `notifications.timeout` s; `critical` ganha um aro laranja pulsando e **não expira**. Clique na gota executa a ação padrão do app, `×` dispensa e o botão laranja dispara a primeira ação extra. As que expiram saem da tela mas ficam na central (`notifications.keep`): `honeyctl toggle notifications` (Super+Shift+N) abre o painel 7 com as últimas 8, "Limpar tudo" e "Não perturbe". Uma gotinha com a contagem de não lidas fica colada ao corpo central até a central ser aberta. `honeyctl dnd on|off|toggle` liga o não perturbe (gotas escondidas, histórico mantido) e `honeyctl lock` esconde as gotas enquanto a tela está bloqueada (evento `lock_state`). Som é opt-in: `notifications.sound = true` com `notifications.sound_file` apontando um arquivo de áudio absoluto (tocado com `pw-play`/`paplay`, nunca em não perturbe). O serviço é registrado 0,4 s depois da partida do shell; notificações enviadas enquanto o shell reinicia se perdem. `modules.notifications = false` desliga tudo.

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

Settings completo, media player, IA, overview Honey e lock screen próprio continuam para etapas posteriores.
