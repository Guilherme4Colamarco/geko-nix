# Arena: aplicar Nunito + Fredoka (2026-10-04)

- **Candidatos:** 3 planejados (opus, sonnet, fable). O 3 caiu por falta de créditos do modelo; seguiram 2 (N-1).
- **Base:** candidato 1 (opus). Confirmado pelo juiz independente (opus) e por leitura própria: único que coloca a Fredoka no relógio, tem `tests/test_fonts.py` (nome de família errado cai em silêncio no fallback) e rodou `Hyprland --verify-config` e `niri validate`.
- **Enxertos do candidato 2:** verificação por contagem após o `sed` do `session.plm` do pleamar-wm (no lugar do `grep -q`); tooltips +1 px (12 -> 13, peso 700); texto do comentário do WM corrigido (não há texto em barra de título).
- **Rejeitado do candidato 2:** relógio em Nunito 700 (mantido só como placeholder `--:--` em Nunito 800 no candidato 1); `font-size=22` do swaylock (não verificado); `dconf.settings` explícito (redundante, o `gtk` do home-manager já grava).
- **Acréscimos próprios após verificação:**
  - `xdg.configFile."gtk-{3,4}.0/settings.ini".force = true` (hoje são arquivos soltos e somente leitura; evita que um backup antigo bloqueie a ativação);
  - `programs.dconf.enable = true` em `honey-common.nix`: a VM do perfil pleamar falhou porque `gtk.font` grava no dconf e o serviço não existia, o que derrubou a ativação inteira do home-manager (niri e hyprland já tinham o dconf ligado).
- **Verificação:** 62 testes OK (4 ignorados); `pleamar --check` em `honey.plm` e `reserve.plm`; `nix eval` das opções; checks de VM `honey-pleamar-core`, `honey-niri` e `honey-hyprland` passam; render real do Honey com as fontes (launcher e wallpapers) mostra Nunito no texto e Fredoka no relógio e títulos.
- **Não verificado:** aparência no desktop real com escala 1,25 na NVIDIA; se os dígitos da Fredoka a peso 600 cabem nas células do relógio em todos os minutos (`clockcell` 0,66 em), só vi 11:12; swaylock e mako não foram renderizados.
