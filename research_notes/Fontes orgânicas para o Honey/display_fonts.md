# Fontes display orgânicas, líquidas e arredondadas (licença livre) para o Honey

Método: o `METADATA.pb` de cada família foi baixado do repositório google/fonts (licença, eixos, subsets, designer). Os TTFs foram baixados e inspecionados com fontTools: cobertura de á à â ã é ê í ó ô õ ú ç (maiúsculas também), feature `tnum`, feature `zero`, se os dígitos padrão já são tabulares, eixos `fvar` e tabelas de cor. Uma prova "10:58 0O 1lI açãí" foi renderizada com Pillow e conferida a olho. Data da verificação: 2026-10-04. Fonte primária de metadados de cada família: `https://github.com/google/fonts/tree/main/<ofl|apache>/<família>/METADATA.pb`.

## Quais fontes livres parecem "líquidas", "gooey", "derretendo" ou "bolha macia" sem virar novidade ilegível?

### Takeaway
Quase nenhuma fonte livre e madura é realmente "líquida". O sweet spot para o Honey está nas fontes **arredondadas e gordinhas** (Fredoka, DynaPuff, Gluten, Grandstander, Baloo 2, Coiny, Modak, Bagel Fat One). A **Rubik Wet Paint** é a única opção madura com gotas que realmente pingam. Ela serve para títulos curtos, não para um relógio que o usuário vê o tempo todo. Shortlist recomendada: **Fredoka, DynaPuff, Gluten, Grandstander, Baloo 2, Coiny, Modak, Bagel Fat One, Rubik Wet Paint** e, como experimental, **Fluma**.

### Cited Findings
Todas as famílias abaixo cobrem 100% dos diacríticos do português (á à â ã é ê í ó ô õ ú ç, maiúsculas e minúsculas), conferido no cmap de cada TTF.

**Shortlist**

1. **Fredoka** (Milena Brandão e Hafontia), OFL. Variável `[wdth 75–125, wght 300–700]`. Descrição oficial: "big, round, bold", com terminais totalmente redondos, contraste zero e formas de "bolha macia" sem distorção. Em `wdth 125` fica larga e balofa, muito "favo/gota". Não tem `tnum` nem `zero`, e os dígitos são proporcionais. O 0 é mais estreito que o O, o 1 tem bandeira e o l é uma haste reta. — [METADATA](https://github.com/google/fonts/tree/main/ofl/fredoka), [repositório](https://github.com/hafontia/Fredoka-One)
2. **DynaPuff** (Toshi Omagari e Jennifer Daniel), OFL. Variável `[wdth 75–100, wght 400–700]`, com ss01 e ss02. O repositório a descreve como "Fun blobby display font". Tem contornos inflados, como se fossem desenhados com marcador, e OpenType que alterna a altura das letras (efeito "mão"). Os dígitos são proporcionais e não há `tnum`. O repositório foi arquivado em 2023-08-28 (somente leitura). — [METADATA](https://github.com/google/fonts/tree/main/ofl/dynapuff), [repositório](https://github.com/googlefonts/dynapuff), [descrição](https://raw.githubusercontent.com/google/fonts/main/ofl/dynapuff/DESCRIPTION.en_us.html)
3. **Gluten** (Tyler Finck, Etcetera Type Co), OFL. Variável `[slnt −13..13, wght 100–900]`. Descrição: "very round, and 100% fun". As formas são gordas, moles e levemente irregulares, com terminais redondos. **Tem `tnum` e `zero`** (zero cortado) e ss01. Classificação: DISPLAY e HANDWRITING. — [METADATA](https://github.com/google/fonts/tree/main/ofl/gluten), [repositório](https://github.com/Etcetera-Type-Co/Gluten)
4. **Grandstander** (Tyler Finck), OFL. Variável `[wght 100–900]`, com upright e itálico. Lembra um pincel redondo, levemente saltitante. **Tem `tnum` e `zero`**, além de salt e ss01. O 1 tem pé e o l tem curva na base, o que os distingue bem. — [METADATA](https://github.com/google/fonts/tree/main/ofl/grandstander), [repositório](https://github.com/Etcetera-Type-Co/Grandstander)
5. **Baloo 2** (Ek Type), OFL. Variável `[wght 400–800]`. Descrição: "affable", com "characteristic bounce". É um sans arredondado com leve modulação, o mais "UI" da lista e o mais legível. **Tem `tnum`**, salt, ss01 e ss02. Subsets incluem vietnamese. — [METADATA](https://github.com/google/fonts/tree/main/ofl/baloo2), [descrição](https://raw.githubusercontent.com/google/fonts/main/ofl/baloo2/DESCRIPTION.en_us.html)
6. **Coiny** (Marcelo Magalhães, São Paulo), OFL. Peso único. Descrição: formas "made with a rounded brush point", "naturally bold". É gordinha com junções que parecem moles. Os dígitos são proporcionais e não há `tnum`. — [METADATA](https://github.com/google/fonts/tree/main/ofl/coiny), [repositório](https://github.com/marcelommp/Coiny)
7. **Modak** (Ek Type), OFL. Peso único, com ss01. Descrição: "sweet plump … portly curves and thin counters", com curvas que "merged into each other". É a mais "mel grosso escorrendo junto" das fontes maduras: contraformas mínimas e massa contínua. Os contadores apertados podem fechar em 28 px. Sem `tnum`. — [METADATA](https://github.com/google/fonts/tree/main/ofl/modak), [descrição](https://raw.githubusercontent.com/google/fonts/main/ofl/modak/DESCRIPTION.en_us.html)
8. **Bagel Fat One** (Kyungwon Kim, JAMO), OFL. Peso único. Descrição: "very heavy/fat font with rounded details … inspired by bread, pastries and sweets", com "large contrast" nos cruzamentos. Tem tema de doce/padaria, compatível com mel. Sem `tnum`. — [METADATA](https://github.com/google/fonts/tree/main/ofl/bagelfatone), [repositório](https://github.com/JAMO-TYPEFACE/BagelFat)
9. **Rubik Wet Paint** (NaN e Luke Prowse), OFL. Peso único. É gerada por script a partir da Rubik, com gotas escorrendo da base das letras. É a mais literal em "melting/drip". **Herda `tnum` e `zero` da Rubik.** As gotas pendem abaixo da linha de base, então é preciso reservar altura extra. — [METADATA](https://github.com/google/fonts/tree/main/ofl/rubikwetpaint), [repositório](https://github.com/NaN-xyz/Rubik-Filtered), [descrição](https://raw.githubusercontent.com/google/fonts/main/ofl/rubikwetpaint/DESCRIPTION.en_us.html)
10. **Fluma** (Baturay Kocatepe), OFL 1.1. Somente Regular, sem eixos. Descrição: "liquid organic display typeface with soft, tapering forms". É a única realmente "líquida": hastes afinam como gotas e os terminais são cônicos. Cobre GF Latin Core, e os diacríticos do português foram conferidos no TTF. Sem `tnum`. **Imatura**: v1.000 de 2026-09-30, 0 estrelas, 12 commits, produção assistida por IA declarada no repositório. Não está no Google Fonts nem no nixpkgs. — [repositório](https://github.com/baturaykocatepe/Fluma-Font)

**Verificadas e descartadas (ou só como reserva)**
- **Rubik Puddles** (OFL): letras feitas de poças contornadas e vazadas. Ficou ilegível na prova a 34 px. — [METADATA](https://github.com/google/fonts/tree/main/ofl/rubikpuddles)
- **Rubik Bubbles** (OFL): contorno de bolhas, legível e "espumoso". Serve de reserva para títulos. Tem `tnum` e `zero`. — [METADATA](https://github.com/google/fonts/tree/main/ofl/rubikbubbles)
- **Rubik Beastly** (OFL): pelos espetados, sem nada de líquido. **Rubik Glitch**, **Moonrocks**, **Vinyl** e **Doodle Shadow** (todas OFL) existem, mas não combinam com o tema. — [METADATA Beastly](https://github.com/google/fonts/tree/main/ofl/rubikbeastly)
- **Nabla** (OFL): fonte de cor COLRv1 isométrica, inspirada em jogos ("inspired by isometric computer games"). Tem eixos `EDPT 0–200` e `EHLT 0–24`. A estética é de bloco 3D, não líquida, e exige um renderizador COLRv1 (o Pillow desenhou só a silhueta). — [descrição](https://raw.githubusercontent.com/google/fonts/main/ofl/nabla/DESCRIPTION.en_us.html)
- **Honk** (OFL, Ek Type): fonte de cor COLRv1 inspirada em "lettering seen on Indian trucks", com eixos `MORF 0–45` e `SHLN 0–100`. Estética de caminhão e caixa alta, fora do tema. — [descrição](https://github.com/google/fonts/blob/main/ofl/honk/DESCRIPTION.en_us.html), [METADATA](https://github.com/google/fonts/tree/main/ofl/honk)
- **Climate Crisis** (OFL): eixo `YEAR 1979–2050` que "derrete" o peso (o conceito é gelo polar). O padrão (1979) é ultrapesado e largo demais para o espaço de um relógio. — [METADATA](https://github.com/google/fonts/tree/main/ofl/climatecrisis)
- **Chango** (OFL): gorda e larga demais. **Titan One** (OFL): arredondada mas rígida. **Shrikhand** (OFL): itálico de letreiro pintado. **Chewy** (Apache 2.0, só subset latin, mas com os diacríticos do português): estilo cartoon. **Sniglet** (OFL, 400/800): redonda leve, sem caráter líquido. — METADATA em google/fonts (`ofl/chango`, `ofl/titanone`, `ofl/shrikhand`, `apache/chewy`, `ofl/sniglet`)
- **Pacifico** e **Lobster** (OFL): scripts. O 0 e o O se confundem e há números estilo caligrafia. Ruins para relógio.
- **Comfortaa** (OFL, `wght 300–700`), **Quicksand** (OFL, `wght 300–700`, tem `zero`), **Varela Round** (OFL, dígitos padrão já tabulares e com `tnum`), **Nunito** (OFL, `wght 200–1000`, dígitos padrão tabulares) e **M PLUS Rounded 1c** (OFL, 7 pesos estáticos, dígitos tabulares): são arredondadas e geométricas, boas para texto, mas não leem como "líquido". Úteis como fonte secundária. — METADATA em google/fonts
- Não foram analisadas a fundo: **Bungee/Bungee Shade** (geométrica, como esperado), **Sixtyfour** (pixel), **Kalam** e **Gochi Hand** (manuscritas). Não combinam com a estética pedida.
- **Velvetyne**: fundição livre que publica em OFL. **Gulax** é "experimental … geometric base with a series of quirks", mais estranha do que líquida. Não achei nenhuma família líquida verificável no catálogo. — [Gulax](https://velvetyne.fr/fonts/gulax/), [Velvetyne/about](https://velvetyne.fr/about/)
- Fontes "Drip – Liquid Font" e similares em sites de fontes grátis são comerciais ou só para uso pessoal (exemplo: Drip, da Tugcu Design Co., vendida no Creative Market). Excluídas. — [Creative Market](https://creativemarket.com/MehmetRehaTugcu/1503577-Drip-Liquid-Font)

**Empacotamento no Nix**: o nixpkgs fixado no flake tem `google-fonts` versão `0-unstable-2026-03-13`, e `google-fonts.override { fonts = [ "Fredoka" ... ]; }` avalia sem erro. Todas as fontes da shortlist, menos a Fluma, saem desse pacote. A Fluma precisaria de um `fetchFromGitHub` próprio. (Conferido com `nix eval` neste repositório.)

### Inferences
- A combinação mais coerente com "mel, gota, favo" e que continua legível a 28–36 px: **Fredoka** (wdth alto, wght 500–600) ou **DynaPuff** para o relógio, e **Modak**, **Bagel Fat One** ou **Rubik Wet Paint** para títulos de destaque curtos.
- Se a prioridade for um relógio que não "pula", **Gluten** e **Grandstander** são as melhores entre as orgânicas, porque têm `tnum` real e um eixo de peso amplo (100–900).
- A Fluma é a mais próxima de "líquido de verdade", mas é arriscada: um projeto de duas semanas com um único autor. Serve como acento, não como fonte principal.

### Gaps
- Não renderizei as fontes de cor (Nabla, Honk) com suporte a COLRv1. A avaliação estética delas se baseia nas descrições oficiais.
- Não conferi se o renderizador de texto do Pleamar 0.2.8 aplica features OpenType (`tnum`) ou eixos variáveis. Isso decide se `tnum` e animações de eixo servem de algo na prática.

## Quais têm eixos variáveis que poderiam ser animados?

### Takeaway
Entre as que combinam com o tema, as melhores para animar são **Fredoka** (`wdth` + `wght`, um "inchar" de bolha), **DynaPuff** (`wdth` + `wght`) e **Gluten** (`wght` 100–900 + `slnt` ±13, um "balançar" de líquido). Grandstander e Baloo 2 só têm `wght`. As Rubik filtradas, Modak, Coiny, Bagel Fat One e Fluma são estáticas.

### Cited Findings
- Fredoka: `wdth 75–125` (padrão 100), `wght 300–700` (padrão no arquivo: 300). — fvar do TTF de [google/fonts ofl/fredoka](https://github.com/google/fonts/tree/main/ofl/fredoka)
- DynaPuff: `wght 400–700`, `wdth 75–100`. — [google/fonts ofl/dynapuff](https://github.com/google/fonts/tree/main/ofl/dynapuff)
- Gluten: `wght 100–900`, `slnt −13..13`. — [google/fonts ofl/gluten](https://github.com/google/fonts/tree/main/ofl/gluten)
- Grandstander: `wght 100–900` (arquivo de itálico separado). — [google/fonts ofl/grandstander](https://github.com/google/fonts/tree/main/ofl/grandstander)
- Baloo 2: `wght 400–800`. — [google/fonts ofl/baloo2](https://github.com/google/fonts/tree/main/ofl/baloo2)
- Comfortaa e Quicksand: `wght 300–700`. Nunito: `wght 200–1000`. — google/fonts
- Nabla: `EDPT 0–200` (profundidade) e `EHLT 0–24` (realce), COLRv1 com várias paletas. — [descrição](https://raw.githubusercontent.com/google/fonts/main/ofl/nabla/DESCRIPTION.en_us.html)
- Honk: `MORF 0–45` e `SHLN 0–100`, COLRv1. — [METADATA](https://github.com/google/fonts/tree/main/ofl/honk)
- Climate Crisis: `YEAR 1979–2050` (o peso "derrete" com os anos). — [METADATA](https://github.com/google/fonts/tree/main/ofl/climatecrisis)
- Rubik Wet Paint, Puddles, Bubbles e Beastly, além de Modak, Coiny, Bagel Fat One, Chango, Shrikhand, Sniglet e Fluma: arquivos estáticos, sem `fvar` (inspecionado).

### Inferences
- Para animar uma "gota inchando" ao abrir um painel, Fredoka `wdth 100→125` com `wght 500→600` é o efeito mais orgânico entre as livres. Climate Crisis tem o único eixo conceitualmente de "derreter", mas a estética é ultrapesada.

### Gaps
- Depende do suporte do Pleamar a variações de fonte em tempo real (não verificado).

## Quais têm bons numerais para um relógio?

### Takeaway
Nenhuma das fontes orgânicas tem dígitos tabulares por padrão. Só **Gluten, Grandstander, Baloo 2 e a família Rubik filtrada** (Wet Paint, Bubbles e outras) oferecem a feature `tnum`. Gluten, Grandstander e Rubik oferecem também `zero` (zero cortado). Sem `tnum`, o relógio "dança" a cada minuto: o 1 é bem mais estreito. Na prova, todas as fontes da shortlist distinguem 0 de O (o 0 é mais estreito e oval) e 1 de l (o 1 tem bandeira).

### Cited Findings
(Feature tags lidas das tabelas GSUB/GPOS e larguras dos dígitos lidas do `hmtx`, nos TTFs de google/fonts. Baixados em 2026-10-04.)
- `tnum` presente: Gluten, Grandstander, Baloo 2, Rubik Wet Paint, Rubik Bubbles, Rubik Puddles, Rubik Beastly e Varela Round. — google/fonts
- `zero` (zero cortado) presente: Gluten, Grandstander, a família Rubik filtrada e Quicksand. — google/fonts
- Dígitos padrão já tabulares (larguras iguais): Nunito, Varela Round e M PLUS Rounded 1c. Nenhuma das fontes "líquidas" está nesse grupo. — google/fonts
- Sem `tnum` e com dígitos proporcionais: Fredoka, DynaPuff, Coiny, Modak, Bagel Fat One, Chango, Shrikhand, Sniglet, Titan One, Chewy, Climate Crisis, Nabla, Honk, Pacifico, Lobster, Comfortaa e Fluma. — google/fonts e [Fluma](https://github.com/baturaykocatepe/Fluma-Font)
- Observação visual (prova "10:58 0O 1lI" a 48 px):
  - Grandstander: o 1 tem pé, o l é curvo e o 0 e o O são bem distintos. É a mais clara.
  - Gluten e Fredoka: o l termina em gancho. O 0 é estreito e o O é redondo.
  - Modak e Bagel Fat One: contadores muito pequenos. O 0 vira quase uma pastilha a 28 px.
  - Rubik Wet Paint: as gotas sob o 1, o 5 e o 8 deixam a leitura ruidosa.
  - Pacifico e Lobster: o 0 e o O se confundem.

### Inferences
- Escolha principal para o relógio: **Grandstander** (wght ~700, `tnum`) ou **Gluten** (wght ~500–600, `tnum` + `zero`), que unem o caráter orgânico a numerais estáveis.
- Se a escolha for Fredoka ou DynaPuff (as mais "bolha"), é preciso fixar a largura de cada dígito no layout (uma célula por dígito, centralizada) para o relógio não tremer.
- Para títulos sem números, vale qualquer fonte da shortlist. Para gotas literais, Rubik Wet Paint.

### Gaps
- Não medi a altura de x nem a legibilidade real em 28 px com antialiasing do compositor e escala 1,25. Recomenda-se uma prova no próprio Pleamar.
