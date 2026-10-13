# Empacotamento das fontes candidatas no NixOS 26.05 e suporte a fontes no pleamar

Método: comandos somente leitura na máquina (2026-10-04). `nix eval --inputs-from /home/geko/Documentos/geko-nix nixpkgs#<attr>` resolve para o nixpkgs travado no `flake.lock` (nixos-26.05, rev `774debe7a0d1b496e35677ad955a1011c6ff74f3`). `nixpkgs-unstable#...` resolve para o input unstable do repo (rev `c59305bab2065cfecc4944690d9eedbb56f3a9fa`). Os arquivos de fonte foram inspecionados direto no source do `google-fonts`, que já está no store (`/nix/store/lki8fz53bclxz55219x1j0bajvxf06mk-source`, 2,8 GB). O código do pleamar foi lido no source do input travado (`k4ditano/pleamar` rev `4163c91a`, `/nix/store/pa5l73cnfyjxcjvj9x0qzv4f7nl0s7rq-source`). O código do cosmic-text 0.19.0 está em `/nix/store/zk0859qrbbqvc948d8l36irimai3i1g3-cosmic-text-0.19.0`. Nada foi construído nem instalado.

## Atributos no nixpkgs para cada candidata (26.05 e unstable) e como instalar

### Takeaway
Só 11 das 22 famílias têm atributo próprio: nunito, quicksand, comfortaa, recursive, fraunces, sniglet, shrikhand, rubik, lexend, atkinson-hyperlegible(-next), além de `mplus-outline-fonts`, que NÃO inclui a Rounded 1c. Todas as 22 (e as variantes da Rubik) estão no `google-fonts` (versão `0-unstable-2026-03-13`) e podem ser escolhidas com `pkgs.google-fonts.override { fonts = [ ... ]; }`. As que faltam também não existem no unstable. Atenção: `pkgs.honk` NÃO é a fonte, é um servidor ActivityPub.

### Cited Findings
Tabela verificada com `nix eval --raw --inputs-from . nixpkgs#<attr>.name` e `.meta.description` (local). As colunas "26.05" e "unstable" mostram o resultado do eval. A coluna "google-fonts" mostra o arquivo achado no source com o mesmo padrão `find` que o installPhase usa:

| Família | Atributo próprio (26.05) | unstable | Nome em `google-fonts` `fonts=[...]` → arquivo instalado |
|---|---|---|---|
| Fredoka | não existe | não existe | `"Fredoka"` → `Fredoka[wdth,wght].ttf` |
| Baloo 2 | não existe (`baloo-widgets` é outra coisa) | não existe | `"Baloo 2"` → `Baloo2[wght].ttf` |
| Nunito | `nunito` = nunito-0-unstable-2025-02-26 (variável, de googlefonts/nunito) | igual | `"Nunito"` → `Nunito[wght].ttf`, `Nunito-Italic[wght].ttf` e TAMBÉM `lang/data/test/nunito/Nunito-Regular.ttf` (arquivo de teste, ver gotchas) |
| Varela Round | não existe | não existe | `"Varela Round"` → `VarelaRound-Regular.ttf` |
| M PLUS Rounded 1c | não existe. `mplus-outline-fonts.{githubRelease,osdnRelease}` = "M+ Outline Fonts", outro projeto | — | `"M PLUS Rounded 1c"` → 7 estáticas (Thin…Black), cerca de 3,3 MB cada |
| Quicksand | `quicksand` = quicksand-2.0-unstable-2021-01-15 (instala a variável e as estáticas) | — | `"Quicksand"` → `Quicksand[wght].ttf` |
| Comfortaa | `comfortaa` = comfortaa-unstable-2021-07-29 (TTF estáticas) | — | `"Comfortaa"` → `Comfortaa[wght].ttf` |
| Recursive | `recursive` = recursive-1.085 (zip do release com todos os .otf e .ttf) | igual | `"Recursive"` → `Recursive[CASL,CRSV,MONO,slnt,wght].ttf` |
| Fraunces | `fraunces` = fraunces-1.000 (estáticas e variáveis) | igual | `"Fraunces"` → `Fraunces[SOFT,WONK,opsz,wght].ttf` e Italic |
| Gluten | não existe | não existe | `"Gluten"` → `Gluten[slnt,wght].ttf` |
| Grandstander | não existe | não existe | `"Grandstander"` → `Grandstander[wght].ttf` e Italic |
| Sniglet | `sniglet` = sniglet-2011-05-25 (League of Moveable Type) | — | `"Sniglet"` → Regular e ExtraBold |
| Shrikhand | `shrikhand` = shrikhand-unstable-2016-03-03 | — | `"Shrikhand"` → Regular |
| Nabla | não existe | não existe | `"Nabla"` → `Nabla[EDPT,EHLT].ttf` |
| Honk | **`honk` = honk-1.5.2, servidor ActivityPub** ("ActivityPub server with minimal setup…"), NÃO é a fonte. No unstable foi removido | removido | `"Honk"` → `Honk[MORF,SHLN].ttf` |
| Rubik | `rubik` = rubik-2.200 (googlefonts/rubik, via `installFonts`) | igual | `"Rubik"` → `Rubik[wght].ttf` e Italic (não puxa RubikPuddles etc., porque o padrão é `Rubik-*`/`Rubik[*`) |
| Rubik Puddles / Wet Paint / Bubbles | não existe | — | `"Rubik Puddles"`, `"Rubik Wet Paint"`, `"Rubik Bubbles"` → `*-Regular.ttf` |
| Lexend | `lexend` = lexend-0.pre+date=2022-09-22 (instala TODA a superfamília Deca/Exa/Giga/…, estáticas e variáveis) | igual | `"Lexend"` → só `Lexend[wght].ttf` |
| Atkinson Hyperlegible | `atkinson-hyperlegible` (2021), `atkinson-hyperlegible-next` (2.001, 2025), `atkinson-hyperlegible-mono` | — | `"Atkinson Hyperlegible"` → 4 estáticas. `"Atkinson Hyperlegible Next"` → `[wght]` e Italic |
| Bagel Fat One | não existe (`bagels` é outra coisa) | não existe | `"Bagel Fat One"` → Regular |
| Pacifico | não existe | não existe | `"Pacifico"` → Regular |
| Mali | não existe | não existe | `"Mali"` → 12 estáticas |
| Zen Maru Gothic | não existe | não existe | `"Zen Maru Gothic"` → 5 estáticas (cerca de 3,7 MB cada) |

- Fonte da tabela: avaliação local. Pacote: [nixpkgs pkgs/by-name/go/google-fonts/package.nix](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/go/google-fonts/package.nix). Também lidos localmente os package.nix de [nunito](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/nu/nunito/package.nix), [rubik](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/ru/rubik/package.nix), [lexend](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/le/lexend/package.nix), [recursive](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/re/recursive/package.nix), [fraunces](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/fr/fraunces/package.nix), [comfortaa](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/co/comfortaa/package.nix), [quicksand](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/qu/quicksand/package.nix) e [mplus-outline-fonts](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/data/fonts/mplus-outline-fonts/default.nix).
- Mecânica do `google-fonts.override` (26.05): o argumento `fonts ? [ ]` tem os espaços removidos (`builtins.replaceStrings [ " " ] [ "" ]`) e, para cada nome, o installPhase roda `find . \( -name "$font-*.ttf" -o -name "$font[*.ttf" -o -name "$font.ttf" \)` e instala em `$out/share/fonts/truetype`. Com lista vazia, instala TODAS as fontes do repositório google/fonts. A Adobe Blank fica num output separado (`adobeBlank`) porque derruba o libfontconfig. — [package.nix](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/go/google-fonts/package.nix)
- O `google-fonts` tem `hydraPlatforms = [ ]`, ou seja, não está no cache binário e é construído localmente a partir do tarball de google/fonts (rev `5174b333…`). Esse source já está no store da máquina (2,8 GB). Também existe no store um build anterior com override (contém só `SpaceGrotesk[wght].ttf`), o que mostra que o padrão já foi usado aqui. — local / [package.nix](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/go/google-fonts/package.nix)
- Nenhuma candidata está instalada hoje: `fc-list : family | grep -i <nome>` voltou vazio para todas as 22. As famílias atuais são DejaVu, FreeFont, Liberation, TeX Gyre, Unifont, Noto CJK e Noto Color Emoji. `fc-match sans-serif` → DejaVu Sans. — local

Snippets de instalação (inferidos dos módulos padrão, não aplicados):
```nix
# Sistema todo (NixOS), por exemplo em configuration.nix ou modules/core/default.nix:
fonts.packages = with pkgs; [
  (google-fonts.override { fonts = [ "Fredoka" "Baloo 2" "Varela Round" "M PLUS Rounded 1c" "Nabla" "Honk" ]; })
  nunito rubik recursive   # atributos próprios
];
# Home Manager (home/default.nix ou home/desktop/honey.nix):
home.packages = [ (pkgs.google-fonts.override { fonts = [ "Fredoka" ]; }) ];
```

### Inferences
- Para o Honey, o caminho mais uniforme é um único `google-fonts.override` com a lista escolhida: um derivation só, arquivos variáveis oficiais e o source já no store (sem baixar 2,8 GB). Os atributos próprios dão versões diferentes (por exemplo, `nunito` vem do repo upstream e `lexend` traz a superfamília inteira) e podem duplicar famílias se forem combinados com o google-fonts.
- Mudar a lista de `fonts` muda o derivation e força um rebuild local (cópia rápida, já que o source está no store). Se o GC limpar o source, o próximo rebuild baixa o tarball inteiro de novo.

### Gaps
- Não consultei o search.nixos.org (web) e confiei no eval local, que é a fonte autoritativa para os dois pins do repo. O unstable foi checado no pin do repo (2026-09), não no HEAD atual.

## Onde declarar no repo e se o fontconfig/pleamar enxerga

### Takeaway
O repo não declara nenhuma fonte (nenhum `fonts.packages` ou `fonts.` em `configuration.nix`, `modules/` ou `home/`). As fontes atuais vêm dos defaults do NixOS. Os dois caminhos funcionam com o pleamar: (a) `fonts.packages` no NixOS, que vira `<dir>` em `/etc/fonts`; (b) `home.packages` no HM, porque `fonts.fontconfig.enable` do HM já é `true` e `~/.config/fontconfig/conf.d/10-hm-fonts.conf` aponta para `/etc/profiles/per-user/geko/share/fonts`. Além disso, o parser de fontconfig do pleamar resolve includes com `prefix="xdg"`.

### Cited Findings
- `grep -rn -iE "font|google-fonts" --include=*.nix` no repo só encontra `fontconfig freetype` em `pkgs/sqldeveloper.nix`. — local
- `nixosConfigurations.niri.config.fonts.packages` = font-cursor-misc, font-misc-misc, font-alias, dejavu-fonts, freefont-ttf, gyre-fonts, liberation-fonts, unifont, noto-fonts-cjk-sans/serif, noto-fonts-color-emoji. Além disso, `fonts.enableDefaultPackages = true`. — local (`nix eval .#nixosConfigurations.niri.config.fonts.packages`)
- `home-manager.users.geko.fonts.fontconfig.enable = true`. Os arquivos `~/.config/fontconfig/conf.d/10-hm-fonts.conf` e `52-hm-default-fonts.conf` existem e listam `<dir>/etc/profiles/per-user/geko/share/fonts</dir>` (por causa de `useUserPackages = true`). — local
- `/etc/fonts/fonts.conf` lista cada pacote de `fonts.packages` como `<dir>/nix/store/...</dir>`, junto com `<dir prefix="xdg">fonts</dir>` e `<include prefix="xdg">fontconfig/conf.d</include>`. — local
- O pleamar compila o cosmic-text no Linux com a feature `fontconfig` (Cargo.toml: "fontconfig gives the system's font aliases ("sans-serif" → whichever it is)"). O fontdb 0.23 usa `fontconfig-parser` 0.5.8, que implementa `DirPrefix::Xdg` (XDG_CONFIG_HOME/XDG_DATA_HOME). — [pleamar Cargo.toml](https://github.com/k4ditano/pleamar/blob/4163c91a649e70d3296d7cae931253fc0f2cc5fc/Cargo.toml); local `/nix/store/yr1fnqm4wv5863kr5qkrlx7sy3qdbbj0-fontconfig-parser-0.5.8/src/types/dir.rs`
- O log atual do Honey: `text   · 97 system fonts in 8 ms` (journal de `honey-shell.service`). O número vem de `fonts.db().len()` (faces do fontdb) em `src/text.rs:143`. — local / [text.rs](https://github.com/k4ditano/pleamar/blob/4163c91a649e70d3296d7cae931253fc0f2cc5fc/src/text.rs)
- As 43 ocorrências de `family:` em `pkgs/honey-shell/source/src/**/*.plm` são todas `family: "DejaVu Sans"`, como literal repetido em cada elemento. Não existe variável de tema de fonte (`core/config.py`, `presets/*.json` e `default.nix` não mencionam fontes). — local

### Inferences
- Melhor lugar: `fonts.packages` em `modules/desktop/honey-common.nix` (comum aos 3 perfis Honey). Alternativa: `home.packages` em `home/desktop/honey.nix`, junto do pacote do shell. Para conferir depois do switch: `fc-list | grep -i fredoka`, e o número de "system fonts" no log do honey-shell deve subir. O shell precisa ser reiniciado, porque o FontSystem é criado uma vez no início.
- Trocar a fonte do Honey hoje exige editar os 43 literais (ou fazer substituição no build). Também daria para gerar a família por `palette()` em `themes/active.plm`, se a linguagem aceitar uma constante string em `family:`. Isso não foi verificado.

### Gaps
- Não testei se `family:` aceita uma referência a constante ou tema em vez de string literal: o compilador faz `c.string()?` em `compiler.rs:2834`, mas não conferi o que `string()` aceita.

## Como o pleamar escolhe fontes: eixos variáveis, features (tnum), fallback e fontes coloridas

### Takeaway
O pleamar passa ao cosmic-text SÓ `family` (ou `SansSerif` quando ausente) e `weight` numérico. Não passa stretch, style (itálico), font features nem outros eixos. O cosmic-text 0.19 aplica o eixo `wght` das fontes variáveis a partir do `weight:`. Os demais eixos (wdth da Fredoka, SOFT/WONK/opsz da Fraunces, CASL/MONO da Recursive, EDPT da Nabla, MORF da Honk) ficam travados no valor default do arquivo. Numerais tabulares (`tnum`) não podem ser ligados. O fallback por glifo existe (lista Noto/DejaVu/Free). Fontes COLRv1 (Nabla, Honk) aparecem monocromáticas.

### Cited Findings
- `src/text.rs` (pleamar 0.2.8): `let attrs = Attrs::new().family(c.family.map_or(Family::SansSerif, Family::Name)).weight(Weight(c.weight));`, seguido de `buffer.set_text(..., Shaping::Advanced, ...)`. Não há `.stretch`, `.style` nem `.font_features`. — [text.rs](https://github.com/k4ditano/pleamar/blob/4163c91a649e70d3296d7cae931253fc0f2cc5fc/src/text.rs)
- A gramática só expõe `properties.text: at anchor width size weight color opacity lines align line_height family measure show grow gradient outline shadow letter_move letter_opacity letter_scale` (e o equivalente em `input`). Não existem palavras para feature, eixo, itálico ou tabular. `pleamar --docs reference/guide/recipes` não falam de fontes além de `family`/`weight`. — `docs/pleamar/grammar.txt:13,19`; `pleamar --docs reference` (local)
- O cosmic-text 0.19 suporta `Attrs::font_features(FontFeatures)` (repassado ao harfrust em `shape.rs`) e `Stretch`/`Style`, mas o pleamar não usa nada disso. — local `/nix/store/zk0859…-cosmic-text-0.19.0/src/attrs.rs:168,377`, `src/shape.rs:156-169`
- Fontes variáveis: o CHANGELOG do cosmic-text traz "Variable font support", "Match variable fonts using wght axis" (PR #486) e "Fix variable font weight". No `swash.rs`, só o tag `wght` é normalizado e aplicado (`normalized_coords([(wght, weight)])`); no `font/system.rs:41`, o eixo `wght` entra no matching. — local cosmic-text src; [cosmic-text PR #486](https://github.com/pop-os/cosmic-text/pull/486)
- Eixos e defaults medidos nos arquivos (tabela `fvar`): Fredoka wght 300–700 (def 300), wdth 75–125 (def 100); Baloo2 wght 400–800; Nunito wght 200–1000; Quicksand 300–700; Comfortaa 300–700; Rubik 300–900; Lexend 100–900; Grandstander 100–900; Gluten wght 100–900 e slnt −13..13; Recursive MONO 0–1 (def 0), CASL 0–1 (def 0), CRSV (def 0.5), slnt, wght 300–1000; Fraunces opsz 9–144 (def 9), wght 100–900 (def 900), SOFT 0–100 (def 0), WONK (def 1); Nabla EDPT 0–200 (def 100), EHLT 0–24; Honk MORF 0–45 (def 15), SHLN 0–100 (def 0). — local (script Python lendo `fvar`)
- Numerais: medi os advances de 0–9 (cmap e hmtx). São tabulares por padrão Nunito (600), Recursive (600), Varela Round (628) e M PLUS Rounded 1c (620). Todas as outras têm dígitos proporcionais: Fredoka, Baloo 2, Rubik, Quicksand, Lexend, Comfortaa, Gluten, Grandstander, Zen Maru Gothic, Atkinson (Next e original), Mali, Fraunces, Bagel Fat One, Sniglet, Pacifico, Shrikhand, Nabla, Honk e as Rubik decorativas. Algumas têm `tnum` no GSUB (Baloo 2, Rubik, Varela Round, Gluten, Grandstander, Atkinson Next), mas o pleamar não consegue ativá-lo. — local
- Fallback: o cosmic-text tem fallback por script e por glifo. A lista Unix inclui "Noto Sans", "DejaVu Sans", "FreeSans", monospace "DejaVu Sans Mono"/"FreeMono", "Noto Color Emoji" e CJK "Noto Sans CJK SC/JP/…". Um glifo ausente na família pedida (por exemplo emoji, CJK ou acentos raros) cai nessas fontes. O próprio pleamar diz no cabeçalho de text.rs: "ligatures, right-to-left languages, emoji, fallback fonts". — local `cosmic-text-0.19.0/src/font/fallback/unix.rs`; [text.rs](https://github.com/k4ditano/pleamar/blob/4163c91a649e70d3296d7cae931253fc0f2cc5fc/src/text.rs)
- Família inexistente não dá erro em `pleamar --check`: `family` é só uma string interned (`compiler.rs:2833-2834`). Na hora de pintar, o cosmic-text cai no fallback (inferência a partir do código; o fallback do matching é do cosmic-text). — local
- Cor: o pleamar trata `SwashContent::Color` (emoji coloridos funcionam). Mas o swash (0.2.7 no store; o Cargo.lock do pleamar fixa 0.2.10) só implementa COLR v0: `layers()` faz busca binária nos BaseGlyphRecords v0. Nabla e Honk têm COLR versão 1 com **0** BaseGlyphRecords v0 e não têm CBDT. Nabla tem uma tabela `SVG `, que o swash não usa. — local `/nix/store/6iyhk2f7…-swash-0.2.7/src/scale/color.rs`; medição local do COLR

### Inferences
- Nabla e Honk devem aparecer como silhuetas de uma cor só (o contorno base do glifo) e perder o efeito 3D/isométrico, que é o motivo de usá-las. Ou seja, servem pouco no Honey sem mudanças no pleamar. Confirmar visualmente se forem consideradas (não testei a renderização; o pleamar usa swash 0.2.10, e não li o source dessa versão).
- Fredoka vai renderizar sempre com wdth=100 (normal). Fraunces fica com SOFT=0/WONK=1/opsz=9 (a versão menos "macia"), e o lado orgânico (SOFT=100) não é acessível. Recursive fica sempre Sans Linear (CASL=0, MONO=0). Os pesos funcionam continuamente via `weight:` nas variáveis.
- Para o relógio e números do Honey (que mudam por segundo ou porcentagem), sem `tnum` só Nunito, Varela Round, M PLUS Rounded 1c ou Recursive evitam o "pulo" de largura. Com as outras, um `width`/`align` fixo em volta do texto ajuda a disfarçar.
- Itálico não é selecionável (sem `style`). As faces Italic instaladas só seriam usadas se o matching do fontdb escolhesse por acaso, o que é improvável com Style::Normal.
- Cuidado com duplicatas: o `google-fonts` com `"Nunito"` também instala `lang/data/test/nunito/Nunito-Regular.ttf` (estática, de teste) ao lado da variável. Duas faces "Nunito" com peso 400 podem tornar o matching ambíguo. O pacote `nunito` próprio evita isso. O mesmo vale para `quicksand` (variável e estáticas) e para combinar o atributo próprio com o google-fonts da mesma família.

### Gaps
- Não confirmei, renderizando, qual face o cosmic-text escolhe quando há duplicatas, nem como as COLRv1 aparecem de fato (exigiria subir uma cena com a fonte instalada, fora do escopo somente leitura).
- Não verifiquei se o swash 0.2.10 (versão travada no Cargo.lock do pleamar) acrescentou COLRv1. O store local só tem o source da 0.2.7.
