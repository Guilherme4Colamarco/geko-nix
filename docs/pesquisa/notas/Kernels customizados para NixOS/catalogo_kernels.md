# Catalogo de kernels customizados/alternativos para NixOS (estado em 2026-10-08)

Nota de metodo: dados lidos via WebFetch (resumo por modelo pequeno) de arquivos raw do GitHub/nixpkgs master e da API do GitHub. Nao foi possivel inspecionar a arvore completa; itens marcados [NAO VERIFICADO] precisam de conferencia (ex.: `nix eval`).

## Quais kernels existem no proprio nixpkgs, e quais estao atuais, removidos ou atrasados?

### Takeaway
No nixpkgs master (out/2026) restam: mainline (6.1, 6.6, 6.12, 6.18 LTS e 7.2), `linux_testing` (7.3-rc6), `linux_zen` (7.2.9-zen1) e `linux_xanmod` (LTS 6.18.55 e main 7.2.9). `linux_lqx`, `linux_libre` e `linux_latest_libre` foram removidos. O estado de `linux_hardened` e `linux_rt` e ambiguo (ver Gaps).

### Cited Findings
- Versoes por serie em kernels-org.json: testing 7.3-rc6; 6.1.189; 6.6.158; 6.12.112; 6.18.55; 7.2.9. Series nao-LTS: testing e 7.2 — [kernels-org.json](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/os-specific/linux/kernel/kernels-org.json)
- `linux_default` aponta para linux_6_18 e `linux_latest` para linux_7_2; ativos: linux_6_1, 6_6, 6_12, 6_18, 7_2, linux_testing — [linux-kernels.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/top-level/linux-kernels.nix)
- Removidos com `throw`: mainline 4.19, 5.4, 5.10, 5.15, 6.9-6.11, 6.13-6.17, 6.19, 7.0, 7.1; variantes linux_lqx, linux_libre, linux_latest_libre, linux_ham, linux_rpi1-4 — [linux-kernels.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/top-level/linux-kernels.nix)
- `linux_zen`: 7.2.9-zen1 (mesma base do mainline latest, sem atraso); config baseada no linux-zen do Arch: preempcao, tick 1000Hz, BFQ, futex WAIT_MULTIPLE, NTSYNC — [zen-kernels.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/os-specific/linux/kernel/zen-kernels.nix)
- `linux_xanmod` (LTS, isLTS=true) = 6.18.55; `linux_xanmod_latest` (main) = 7.2.9; inclui BBRv3 e governor performance — [xanmod-kernels.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/os-specific/linux/kernel/xanmod-kernels.nix). Aliases `linux_xanmod_stable` tambem listados em linux-kernels.nix.
- Liquorix (`linux_lqx`) removido por falta de manutencao nos padroes de kernel do nixpkgs — resultado de busca que cita commits, [busca / commits espelhados](https://code.ornl.gov/nix/nixpkgs/-/commit/0945795c642bac36c30a47099cf685e8ca9e41f7)
- linux_libre removido; re-adicao improvavel pela regra "no new downstream kernel" — [Discourse](https://discourse.nixos.org/t/does-nixos-plan-to-support-linux-libre-again/77617)
- Politica: kernels LTS sao removidos antes do proximo NixOS estavel que excederia o periodo de manutencao do upstream — mesma busca acima.
- A maquina do usuario roda 6.18.55 (Linux 6.18.55 no ambiente), igual a versao 6.18 do nixpkgs master.

### Inferences
- Zen e Xanmod sao os unicos "sabores" patcheados mantidos no nixpkgs; quem quer Liquorix, libre ou CachyOS precisa de fonte externa.
- Para a faixa 6.18 LTS, `linux_6_18`, `linux_xanmod` (LTS) e `linuxPackages_cachyos-lts` (se acompanhar 6.18) sao equivalentes em base.

### Gaps
- `linux_hardened`: o resumo do linux-kernels.nix listou `linux_hardened` e varias `linux_X_hardened` como removidos, mas tambem citou "linux_hardened so contem latest stable e latest LTS". Contraditorio; o diretorio `kernel/hardened/kernels.json` retornou 404 no caminho tentado. Confirmar com `nix eval nixpkgs#linuxPackages_hardened.kernel.version`.
- `linux_rt`: resumo diz que rt_5_4..rt_6_6 foram removidos; nao confirmei se rt_6_12/6_18 existem. Nota: PREEMPT_RT esta no mainline desde 6.12, entao pode-se usar `linux_6_x` com `structuredExtraConfig` — [NAO VERIFICADO no nixpkgs].
- Sem busca no search.nixos.org (nao acessivel via fetch) nem na wiki do NixOS.

## Quais kernels vem de flakes/repos externos, e o chaotic-nyx ainda e mantido em 2026?

### Takeaway
Ambos os repositorios estao ativos: chaotic-cx/nyx teve push em 2026-10-08 e xddxdd/nix-cachyos-kernel em 2026-10-07; nenhum esta arquivado segundo a API do GitHub. Uma fonte de busca afirmava que o nyx foi arquivado em 2025-12-08, o que contradiz a API (dado primario e recente).

### Cited Findings
- chaotic-cx/nyx: `archived: false`, ultimo push 2026-10-08 14:08 UTC; descricao "Nix flake for 'too much bleeding-edge' and unreleased packages" (mesa_git, linux_cachyos, firefox_nightly) — [API GitHub](https://api.github.com/repos/chaotic-cx/nyx)
- README do nyx diz "WE'RE BACK FROM THE DEAD!", sem aviso de arquivamento; cache `nyx-cache.chaotic.cx`; 7.804 commits — [repo](https://github.com/chaotic-cx/nyx) (resumo por modelo, baixa confianca nos detalhes)
- Contradicao: resultado de busca afirmou "Chaotic's Nyx foi arquivado em 2025-12-08" e que nix-cachyos-kernel virou o caminho principal — [resultado de busca](https://discourse.nixos.org/t/packaging-cachyos-in-nixpkgs/75521) (snippet nao confirmado na pagina); contradito por [API GitHub](https://api.github.com/repos/chaotic-cx/nyx). Possibilidade: foi arquivado e reaberto/"voltou dos mortos".
- Nyx define 11 variantes cachyos: cachyos-gcc (EEVDF), lts, bmq, bore, eevdf, rc (Clang ThinLTO), lto, lto-znver4, rt-bore, server (EEVDF), hardened (BORE); versoes vem de manifestos JSON (manifest.json, manifest-lts.json) — [pkgs/linux-cachyos/default.nix](https://raw.githubusercontent.com/chaotic-cx/nyx/main/pkgs/linux-cachyos/default.nix)
- xddxdd/nix-cachyos-kernel: `archived: false`, push 2026-10-07; 418 commits, 736 estrelas, GPL-2.0 — [API](https://api.github.com/repos/xddxdd/nix-cachyos-kernel), [repo](https://github.com/xddxdd/nix-cachyos-kernel)
- Pacotes: `linuxPackages-cachyos-{latest,lts,bore,...}[-lto][-cpu-arch]`; variantes bmq, deckify, eevdf, hardened, rc, rt-bore, server; canais latest, lts, rc; sincronizacao diaria por GitHub Action com a CachyOS; Hydra CI; cache binario `attic.xuyh0120.win/lantian`; variantes LTO pouco usadas nao sao cacheadas; modulo ZFS patcheado pode falhar; overlay `pinned` recomendado para acertar o cache; so x86_64-linux — [README](https://raw.githubusercontent.com/xddxdd/nix-cachyos-kernel/master/README.md)
- Outros repos encontrados na busca (nao avaliados): drakon64/nixos-cachyos-kernel, omuhr/nixos-rog-cachyos-kernel, ionthedev/chaotic-nyx (fork) — [busca](https://github.com/drakon64/nixos-cachyos-kernel)
- Discussao sobre empacotar CachyOS no nixpkgs: [Discourse](https://discourse.nixos.org/t/packaging-cachyos-in-nixpkgs/75521) (conteudo nao lido).

### Inferences
- Para CachyOS hoje a opcao mais segura e nix-cachyos-kernel (CI/cache documentados, sync diario); nyx ainda recebe commits mas o historico de "morreu/voltou" sugere risco.
- Nyx usa nixpkgs proprio no input (flake.lock do nix-cachyos-kernel usa nixos-unstable-small), logo usar `inputs.nixpkgs.follows` e o cache correto merece atencao.

### Gaps
- Nao pesquisei TKG, Clear Linux, bore avulso, liquorix externo (ex.: flakes que reempacotam lqx), nem Asahi/rpi. Nenhum encontrado nas fontes lidas.
- Nao confirmei a data/historico exato de arquivamento/reativacao do nyx.

## Quais variantes, schedulers e otimizacoes cada um oferece?

### Takeaway
Zen/Xanmod do nixpkgs sao kernels unicos (sem variantes de scheduler); CachyOS (nyx e nix-cachyos-kernel) oferece BORE, EEVDF, BMQ, RT-BORE, server, hardened, deckify, ThinLTO, niveis x86-64-v1..v4 e Zen4, e AutoFDO opcional.

### Cited Findings
- nix-cachyos-kernel: EEVDF (padrao), BORE, BMQ, RT; Clang+ThinLTO nas variantes `-lto`; x86-64-v1 a v4 e znver4; AutoFDO opcional — [README](https://github.com/xddxdd/nix-cachyos-kernel)
- nyx: cachyos-lto-znver4, cachyos-rc com ThinLTO, hardened sobre BORE — [default.nix](https://raw.githubusercontent.com/chaotic-cx/nyx/main/pkgs/linux-cachyos/default.nix)
- nyx README: sched-ext disponivel em kernels upstream a partir da 6.12 — [repo](https://github.com/chaotic-cx/nyx)
- Zen: preempt, 1000Hz, BFQ, NTSYNC (acima). Xanmod: BBRv3, governor performance (acima).
- PGO: nao encontrei em nenhuma fonte lida; so AutoFDO citado.

### Inferences
- scx_* schedulers (sched_ext) funcionam em qualquer kernel >= 6.12 com CONFIG_SCHED_CLASS_EXT, inclusive o mainline 6.18/7.2 do nixpkgs [NAO VERIFICADO que a config do nixpkgs o habilita]; `services.scx` existe no NixOS [conhecimento previo, nao verificado agora].
- x86-64-v3 so via CachyOS; para o AMD do usuario, `-lto-znver4` so serve se a CPU for Zen 4/5 (conferir).

### Gaps
- Matriz exata de pacotes/sufixos v2/v3/v4 por variante e quais tem cache binario nao foi enumerada.
- PGO real: nao confirmado.

## Qual versao do kernel cada um acompanha agora?

### Takeaway
nixpkgs: latest = 7.2.9 (zen, xanmod main, linux_latest), LTS = 6.18.55 (default e xanmod LTS), testing 7.3-rc6. CachyOS: versoes exatas nao verificadas; acompanham o upstream CachyOS (latest/lts/rc).

### Cited Findings
- Ver tabela do primeiro bloco: 7.2.9 / 6.18.55 / 6.12.112 / 6.6.158 / 6.1.189 / 7.3-rc6 — [kernels-org.json](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/os-specific/linux/kernel/kernels-org.json)
- Zen 7.2.9-zen1; Xanmod 6.18.55 (LTS) e 7.2.9 (main) — links acima.
- CachyOS: canais latest/lts/rc com sync diario; sem numeros de versao nas fontes lidas — [README](https://raw.githubusercontent.com/xddxdd/nix-cachyos-kernel/master/README.md)

### Inferences
- Pelo padrao CachyOS, `-latest` provavelmente em 7.2.x, `-lts` em 6.18.x e `-rc` em 7.3-rcN, mas isso e inferencia.

### Gaps
- Versoes reais de manifest.json/manifest-lts.json do nyx e do nix-cachyos-kernel nao lidas; Liquorix externo nao pesquisado.
