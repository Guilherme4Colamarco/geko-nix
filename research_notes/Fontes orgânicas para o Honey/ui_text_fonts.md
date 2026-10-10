# Fontes de texto de UI orgânicas e legíveis para o Honey (10–14 px)

Método: além das fontes web, baixei os TTFs oficiais do repositório `google/fonts` (branch `main`, 2026-10-04) e medi com fontTools: razão x-height/UPM, presença de tabelas de hinting (`fpgm`/`prep`), cobertura dos diacríticos do português (ãõçéêáâíóôúà + maiúsculas + ü) e largura das caixas de `I` e `l` (para saber se há serifa no I ou cauda no l). Renderizei uma amostra com FreeType (Pillow, hinting padrão, tons de cinza) em âmbar sobre fundo escuro a 11, 12 e 13 px: `ui_text_sample_11-13px.png` e `ui_text_sample_12px_zoom2x.png`, nesta mesma pasta. "Medição local" abaixo significa esse procedimento; não é fonte externa.

Tabela de medições locais (UPM normalizado; DejaVu Sans, a fonte atual do Honey, como referência):

| Fonte | x-height/UPM | x/cap | Hint (fpgm) | PT ok | I vs l (largura da caixa) | Leitura de Il1 |
|---|---|---|---|---|---|---|
| DejaVu Sans (atual) | 0.547 | 0.750 | sim | sim | 202 / 184 | ambíguo (só altura) |
| Inter | 0.546 | 0.750 | sim | sim | 190 / 180 | ambíguo por padrão; `ss02`/`cv05`/`cv08` resolvem |
| Nunito | 0.484 | 0.687 | sim | sim | 42 / 184 | l com cauda: resolvido |
| Nunito Sans | 0.484 | 0.687 | sim | sim | 42 / 183 | l com cauda |
| Varela Round | 0.510 | 0.731 | sim | sim | 91 / 91 | ambíguo (l mais alto que I) |
| M PLUS Rounded 1c | 0.520 | 0.712 | sim | sim | 86 / 80 | ambíguo |
| Quicksand | 0.503 | 0.719 | sim | sim | 42 / 40 | ambíguo, traço fino |
| Comfortaa | 0.547 | 0.700 | sim | sim | 78 / 196 | l com cauda |
| Fredoka | 0.500 | 0.714 | sim | sim | 59 / 171 | l com cauda |
| Rubik | 0.520 | 0.743 | sim | sim | 63 / 61 | ambíguo |
| Lexend | 0.525 | 0.750 | sim | sim | 334 / 103 | I com serifa: resolvido |
| Atkinson Hyperlegible | 0.496 | 0.743 | sim | sim | 282 / 154 | I com serifa e l com cauda |
| Atkinson Hyperlegible Next | 0.496 | 0.743 | sim | sim | 282 / 174 | I com serifa e l com cauda |
| Figtree | 0.500 | 0.714 | sim | sim | 64 / 60 | ambíguo |
| Outfit | 0.460 | 0.680 | sim | sim | 32 / 31 | ambíguo, x-height baixa |
| Manrope | 0.540 | 0.750 | sim | sim | 84 / 84 | ambíguo |
| Recursive | 0.526 | 0.751 | sim | sim | 340 / 228 | I com serifa e l com cauda |
| Sniglet | 0.500 | 0.714 | sim | sim | 104 / 100 | ambíguo |
| Mali | 0.500 | 0.714 | **não** | sim | 374 / 82 | I com serifa |
| Itim | 0.474 | 0.746 | sim | sim | 287 / 201 | I com serifa |
| Andika | 0.508 | 0.700 | sim | sim | 675 / 225 | I com serifa e l com cauda |
| Baloo 2 | 0.460 | 0.764 | sim | sim | 81 / 80 | ambíguo |
| Zen Maru Gothic | 0.479 | 0.684 | **não** | sim | 61 / 61 | ambíguo |
| Kosugi Maru | 0.533 | 0.699 | sim | **NÃO** | 99 / 94 | ambíguo |
| SUSE | 0.472 | 0.674 | sim | sim | 296 / 244 | I com serifa e l com cauda |
| Onest | 0.527 | 0.745 | sim | sim | 87 / 85 | ambíguo |
| Albert Sans | 0.500 | 0.714 | sim | sim | 80 / 75 | ambíguo |

(Medição local. "Hint sim" quer dizer que o TTF do google/fonts traz instruções TrueType, em geral geradas por ttfautohint. Isso não garante hinting manual de qualidade.)

## Quais fontes arredondadas ou humanistas livres são comprovadamente legíveis a 10–14 px?

### Takeaway
Nenhuma fonte arredondada tem estudo formal de legibilidade em UI pequena. As que têm evidência (Atkinson Hyperlegible, Lexend, Andika) não são arredondadas, mas são abertas e calorosas. A melhor combinação entre "mel macio" e leitura a 11–13 px é **Nunito** (terminais redondos, l com cauda, variável de 200 a 1000), seguida de **Varela Round** e **M PLUS Rounded 1c**. **Atkinson Hyperlegible Next** e **Recursive** são as opções "à prova de confusão", e **Inter** fica como linha de base neutra. Quicksand, Comfortaa, Fredoka, Baloo 2, Sniglet, Mali e Itim são fontes de display ou de personalidade: servem para títulos, não para listas a 11 px.

### Cited Findings
**Lista curta recomendada (texto de UI):**

1. **Nunito** (OFL; Vernon Adams, Cyreal, Jacques Le Bailly; variável `wght` 200–1000, com itálico; latin e latin-ext) — [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/nunito)
   - É uma sans com terminais totalmente arredondados, sobre base grotesca de baixo contraste, aberturas abertas e x-height generosa. — [Typogram/FontDiscovery](https://typogram.co/font-discovery/proxima-nova-vs-nunito-same-genre-different-feeling)
   - Nunito Sans é a irmã de terminais retos, criada por Le Bailly depois da morte de Adams em 2016 (eixos `wght`, `wdth` 75–125, `opsz` 6–12 e `YTLC` 440–540). — [Typogram](https://typogram.co/font-discovery/proxima-nova-vs-nunito-same-genre-different-feeling); eixos em [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/nunitosans)
   - Medição local: x-height 0.484, menor que a DejaVu (0.547), então precisa de cerca de 1 px a mais para o mesmo olho. O l tem cauda, o que separa bem I, l e 1. Na amostra a 11 px fica limpa, embora um pouco miúda.
   - nixpkgs: `nunito` (0-unstable-2025-02-26) — medição local com `nix eval`.
2. **Varela Round** (OFL; Joe Prince; só 400; latin-ext). O Google descreve que os cantos arredondados dão "soft feel" e que ela "work[s] great at any size". — [google/fonts DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/varelaround)
   - Medição local: x-height 0.510. I e l têm a mesma largura, e só a altura os distingue. Sem negrito, a hierarquia depende de cor e tamanho. Não está em nixpkgs como pacote próprio, mas dá para usar `google-fonts.override { fonts = ["VarelaRound"]; }`. A existência de `google-fonts` (0-unstable-2026-03-13) foi verificada localmente; o mecanismo `override fonts` é de conhecimento geral e deve ser conferido.
3. **M PLUS Rounded 1c** (OFL; Coji Morishita, M+ Fonts Project; 7 pesos estáticos de 100 a 900; inclui japonês, cerca de 8.500 glifos) — [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/mplusrounded1c)
   - Medição local: x-height 0.520, cantos redondos de verdade, aspecto "maru gothic". O arquivo é grande (3,4 MB por peso). I e l são ambíguos.
4. **Atkinson Hyperlegible Next** (OFL no Google Fonts; variável `wght` 200–800, com itálico; adicionada em 2025-01-07) — [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext)
   - O Braille Institute a desenhou para leitores com baixa visão, com "unambiguous letterforms", contraformas abertas e esporas e caudas para diferenciar pares. A Next (2025) tem 7 pesos e cobre mais de 150 idiomas; a original (2019) tinha 2 pesos e 27 idiomas. Existe também a Atkinson Hyperlegible Mono. — [Braille Institute](https://www.brailleinstitute.org/freefont/)
   - Medição local: I com serifa e l com cauda. O zero tem barra (visível na amostra), então O e 0 se distinguem. É a escolha de máxima clareza, mas tem pouco de "orgânico": é humanista com detalhes peculiares e nenhum terminal redondo.
   - nixpkgs: `atkinson-hyperlegible-next` 2.001 e `atkinson-hyperlegible-mono` — medição local.
5. **Recursive** (OFL; Arrow Type, Stephen Nixon; eixos `wght` 300–1000, `CASL` 0–1, `MONO` 0–1, `slnt` 0 a −15, `CRSV` 0/0,5/1) — [arrowtype/recursive](https://github.com/arrowtype/recursive); [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/recursive)
   - CASL 0 ("Linear") tem formas racionalizadas e compactas para texto longo. CASL 1 ("Casual") vem da pintura de letreiros de traço único, mais calorosa. Valores intermediários de CASL e slant funcionam em tamanho de texto. Os pesos 300–800 rendem melhor entre 8 e 72 px. — [arrowtype/recursive](https://github.com/arrowtype/recursive)
   - Medição local: x-height 0.526. I com serifa, l com cauda e 1 com bandeira resolvem Il1. Na amostra a 12 px com hinting do FreeType, **a diferença entre CASL 0 e CASL 1 quase some**, e o caráter casual só aparece de uns 14 px para cima. O TTF variável completo pesa 2,4 MB.
   - nixpkgs: `recursive` 1.085 — medição local.
6. **Rubik** (OFL; Hubert & Fischer; "slightly rounded corners"; `wght` 300–900 com itálico) — [google/fonts DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/rubik)
   - Medição local: x-height 0.520 e boa massa a 11 px. Os cantos arredondados são sutis e somem em tamanho pequeno; o resultado parece "macio e gordinho", não "líquido". I e l são ambíguos. nixpkgs: `rubik` 2.200.
7. **Lexend** (OFL; Bonnie Shaver-Troup, Thomas Jockin e outros; `wght` 100–900). No Google Fonts as larguras saem como famílias separadas (Deca, Exa, Giga, Mega, Peta, Tera, Zetta). — [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/lexend); [lexend.com](https://www.lexend.com/)
   - Evidência: num estudo com 20 alunos de 3º ano, 17 leram melhor com Lexend do que com Times New Roman (média de +19,8% de WCPM, de 110 para 128). A ressalva é "no one setting worked best for all students". — [lexend.com](https://www.lexend.com/)
   - Medição local: I com serifa e x-height 0.525. É uma geométrica limpa, pouco orgânica, e é larga, o que custa espaço no launcher.
8. **Andika** (OFL; SIL International; 400 e 700 com itálico; mais de 4.700 glifos), feita para alfabetização, com formas "not readily confused with one another". — [google/fonts DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/andika)
   - Medição local: I com serifa, l com cauda e "a"/"g" de uma só bacia (estilo escolar). Tem um calor humanista e infantil. nixpkgs: `andika` 7.000.
9. **Inter** (linha de base; OFL; `opsz` 14–32 e `wght` 100–900, com itálico) — [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/inter)
   - `ss02` é o conjunto de desambiguação; `cv05` dá cauda ao l, `cv08` dá serifa ao I e `zero` corta o zero. A versão "Text" tem x-height alta e ink traps. — [rsms.me/inter](https://rsms.me/inter/)
   - Medição local: x-height 0.546, igual à da DejaVu. É neutra e nada orgânica. nixpkgs: `inter` 4.1.

**Descartadas ou rebaixadas para texto de UI:**
- **Quicksand** é "a display sans serif with rounded terminals", desenhada para display mas "kept legible enough to use in small sizes". `wght` 300–700. — [google/fonts DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/quicksand). Na amostra local o traço fica fino e claro demais a 11 px sobre fundo escuro, e I/l/| ficam ambíguos.
- **Comfortaa** é "a rounded geometric sans-serif type design intended for large sizes". — [google/fonts DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/comfortaa). É larga e geométrica, e a 11 px o "a" de uma bacia e o espaçamento largo atrapalham.
- **Fredoka** é "a big, round, bold font ... perfect for ... headline or large text". `wdth` 75–125 e `wght` 300–700. — [google/fonts DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/fredoka). Ótima como display (ver pareamento).
- **Baloo 2** é um "affable display typeface" (pesos 400–800). — [google/fonts DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/baloo2). Medição local: x-height só 0.460 e cap 0.602, pequena para o tamanho nominal.
- **Mali** é inspirada na letra de um aluno de 6º ano, "carefree and naive". — [google/fonts DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/mali). Medição local: o TTF **não traz hinting**.
- **Itim** e **Sniglet**: medição local mostra traço irregular e personalidade forte a 11 px. São fontes de display.
- **Zen Maru Gothic** é "rounded ... soft and natural impression" (OFL; 300–900). — [google/fonts DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/zenmarugothic). Medição local: **sem hinting**, x-height 0.479 e arquivo de 3,8 MB por peso. É bonita, mas fica atrás de M PLUS Rounded 1c.
- **Kosugi Maru** (Apache 2.0; só 400) — [google/fonts METADATA](https://github.com/google/fonts/tree/main/apache/kosugimaru). Medição local: **não tem nenhum dos diacríticos do português** (ã, ç, é…), e "Configurações" aparece com caixas vazias. **Excluída.**
- **Figtree, Outfit, Manrope, Onest, Albert Sans, SUSE**: todas OFL e variáveis (ver METADATA no google/fonts), mas são geométricas ou grotescas de terminais retos, sem nada de "orgânico". Outfit tem x-height de 0.460 (baixa). SUSE resolve Il1 (I com serifa, l com cauda), mas tem x-height 0.472. Servem como alternativa neutra, não para o tema mel. — medição local e [google/fonts](https://github.com/google/fonts/tree/main/ofl)

### Inferences
- Para o Honey, o conjunto mais coerente é **Nunito em 400/600 a 12–13 px** (equivalente óptico a uns 11–12 px de DejaVu, por causa da x-height menor), com **Nunito Sans** como opção mais compacta para listas densas. Nunito Sans tem eixo `opsz` 6–12 próprio para tamanhos pequenos e é da mesma família, o que mantém a coesão.
- Se a prioridade for zero confusão (por exemplo, senhas de Wi-Fi ou nomes de rede no tray), use Atkinson Hyperlegible Next ou Recursive (CASL 0,5 a 1) só nesses campos. Também é possível ativar `ss02` na Inter, se o renderizador do Pleamar aplicar features OpenType.
- Fontes com x-height de 0.46–0.48 (Nunito, Zen Maru, Baloo 2, Outfit, SUSE) precisam de 1 px a mais que a DejaVu atual (0.547) para a mesma legibilidade. Isso pode exigir ajustar larguras no `honey.plm`.

### Gaps
- Não achei estudo empírico de legibilidade em UI pequena para nenhuma fonte arredondada (Nunito, Varela Round, M PLUS Rounded). A evidência aqui é medição de métricas e inspeção visual.
- O estudo da Lexend é pequeno (n=20) e compara com Times New Roman, não com outras sans de UI.
- Não verifiquei se o Pleamar 0.2.8 rasteriza texto com FreeType/fontconfig ou com um rasterizador próprio na GPU, nem se aplica features OpenType (`ss02`, `cv05`) e eixos variáveis. Isso decide se CASL, `opsz` e as features de desambiguação servem para alguma coisa. Confira em `pleamar --docs`.

## Quais têm eixo variável de "casual" ou "suavidade/arredondamento"?

### Takeaway
Entre as fontes de texto, só a **Recursive** tem eixo casual de verdade (`CASL` 0–1). A **Fraunces** tem `SOFT` (0–100) e `WONK` (0–1), mas é uma serifada de display "Old Style" e não serve para UI a 11 px. Nunito, Varela Round, M PLUS Rounded, Zen Maru e Rubik são arredondadas por desenho, sem eixo. A Nunito Sans traz `YTLC` (altura das minúsculas, 440–540) e `opsz` (6–12), úteis para ajuste fino em tamanho pequeno.

### Cited Findings
- Recursive: `CASL` vai de 0 (Linear) a 1 (Casual), inspirado em letreiros de traço único. Valores intermediários são indicados em tamanho de texto, e em display o ideal é ficar nos extremos. — [arrowtype/recursive](https://github.com/arrowtype/recursive)
- Fraunces (OFL; Undercase Type): eixos `wght`, `opsz` (9–144), `SOFT` (0–100) e `WONK` (0–1). O `SOFT` controla a "wetness" ou "inkiness" do tipo; o `WONK` troca glifos "wonky", como a inclinação de h, n e m no romano e os terminais em gota de b, d, h, k, l, v e w no itálico. É descrita como "display, 'Old Style' soft-serif", inspirada em Windsor, Souvenir e Cooper. — [google/fonts DESCRIPTION/METADATA](https://github.com/google/fonts/tree/main/ofl/fraunces). nixpkgs: `fraunces` 1.000 (medição local).
- Nunito Sans: `opsz` 6–12, `wdth` 75–125, `wght` 200–1000 e `YTLC` 440–540. — [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/nunitosans)
- Fredoka: `wdth` 75–125 e `wght` 300–700, sem eixo de suavidade. — [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/fredoka)
- Inter: `opsz` 14–32, com estilos Text e Display. — [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/inter); [rsms.me/inter](https://rsms.me/inter/)

### Inferences
- A "suavidade" com efeito visível a 11–13 px vem do desenho (terminais redondos e aberturas largas), não de eixo. Na amostra local, o efeito do CASL da Recursive quase desaparece a 12 px com hinting.
- A Fraunces com SOFT=100 e WONK=1 pode ser uma serifada de display com cara de mel derretido, para relógio grande ou títulos de painel, ao lado de Nunito no texto.

### Gaps
- Não encontrei outra sans de texto OFL com eixo de arredondamento (algo como "ROND"). Fora do Google Fonts pode existir alguma, mas não verifiquei.

## Problemas conhecidos de renderização no Linux e notas de pareamento

### Takeaway
Não achei relatos de bug específicos para as candidatas. Os riscos práticos são três. Primeiro, a falta de hinting em **Mali** e **Zen Maru Gothic**. Segundo, o aspecto claro e borrado que o FreeType dá por padrão (grayscale + hintslight) a traços finos (Quicksand, Nunito 200–300, Outfit). Terceiro, fontes CJK muito grandes (M PLUS Rounded 1c, Zen Maru, Kosugi) carregam milhares de glifos sem necessidade. Sobre âmbar translúcido, use peso de 450 a 600.

### Cited Findings
- No Linux, o FreeType rasteriza e o fontconfig define as regras. A maioria das distros usa grayscale com hinting leve, e as fontes ficam mais claras e suaves do que no Windows. Uma correção comum é `FREETYPE_PROPERTIES="cff:no-stem-darkening=0 autofitter:no-stem-darkening=0"` (stem darkening). — [saf1.me: Fixing Font Rendering on Linux](https://saf1.me/blog/linux-font-rendering/)
- A Inter, usada no elementary OS, pode parecer borrada no Linux; a mesma fonte sugere stem darkening ou o interpretador v35. — [saf1.me](https://saf1.me/blog/linux-font-rendering/)
- Medição local: Mali e Zen Maru Gothic não têm `fpgm`/`prep`. Todas as outras do google/fonts têm.
- Medição local de tamanho de arquivo: Nunito VF 277 KB, Recursive VF 2,4 MB, Inter VF 877 KB, M PLUS Rounded 1c 3,4 MB por peso, Zen Maru 3,8 MB por peso, Kosugi Maru 3,6 MB.
- Disponibilidade em nixpkgs (medição local, `nix eval` na config `nixos` do flake): `nunito`, `inter` 4.1, `recursive` 1.085, `atkinson-hyperlegible`, `atkinson-hyperlegible-next`, `atkinson-hyperlegible-mono`, `lexend`, `fraunces`, `andika` 7.000, `rubik` 2.200, `quicksand`, `comfortaa`, `figtree` 2.0.3 e `google-fonts`. **Não existem** como atributo próprio: manrope, fredoka, onest, outfit, varela-round, zen-maru-gothic, baloo2, albert-sans e suse. Para essas, use `google-fonts` com `fonts = [...]`.
- Licenças: todas as candidatas estão sob OFL no google/fonts, exceto Kosugi Maru (Apache 2.0, já excluída por falta de diacríticos). A página do Braille Institute descreve a Atkinson apenas como "Free for personal use and all commercial applications". A redistribuição em distro está coberta pela OFL do google/fonts e pelo pacote em nixpkgs. — [Braille Institute](https://www.brailleinstitute.org/freefont/); [google/fonts METADATA](https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext)
- Pareamento com display lúdico/líquido (a parte de display é coberta por outro pesquisador):
  - **Nunito com Fredoka**: as duas têm terminais redondos e l com cauda (medição local), então a família parece uma só. Fredoka é feita para títulos. — [Fredoka DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/fredoka)
  - **Nunito Sans ou Nunito com Fraunces (SOFT 100, WONK 1)**: contraste entre sans macia e serifada "molhada". — [Fraunces DESCRIPTION](https://github.com/google/fonts/tree/main/ofl/fraunces)
  - **Recursive com Recursive**: CASL 1 em peso alto para display e CASL 0–0,5 para o texto, numa família única com variante mono para números e relógio. — [arrowtype/recursive](https://github.com/arrowtype/recursive)
  - **M PLUS Rounded 1c ou Varela Round com Baloo 2 ou Fredoka**: arredondadas por toda parte, para um visual mais "goma/doce".
  - **Atkinson Hyperlegible Next com qualquer display redondo**: neutra o bastante para não brigar com a display, mas sem calor próprio.

### Inferences
- Sobre âmbar translúcido com fundo arbitrário, o contraste varia. Pesos 200–300 de Nunito ou Quicksand vão sumir; prefira 500–600 a 11–12 px e 400–500 a 13–14 px. Pode valer ativar stem darkening no sistema (`FREETYPE_PROPERTIES`), se o Pleamar usar FreeType.
- Recomendação final para teste no Honey: (1) **Nunito**, (2) **Nunito Sans** para listas densas, (3) **Varela Round**, (4) **M PLUS Rounded 1c**, (5) **Recursive** com CASL 1, (6) **Atkinson Hyperlegible Next**, com Rubik e Andika como alternativas e Inter como controle.

### Gaps
- Não achei issues públicas sobre falhas de renderização a 10–14 px no FreeType para Nunito, Varela Round, M PLUS Rounded ou Recursive. A ausência de relato não prova que não há problema.
- A amostra local foi renderizada com Pillow e FreeType (hinting padrão, sem subpixel). O rasterizador real do Pleamar pode dar resultado diferente; o próximo passo é testar dentro do `honey.plm`.
