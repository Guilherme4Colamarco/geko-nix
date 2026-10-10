# Kernels customizados no NixOS (NVIDIA + AMD CPU + btrfs + gaming), outubro de 2026

Nota de escopo: pesquisa limitada (cerca de 12 chamadas). Vários resultados vieram só como snippet de busca; Phoronix devolveu 403 em fetch. Onde não há fonte, está em Gaps.

## Compatibilidade do driver NVIDIA com kernels novos e com Zen/XanMod/CachyOS

### Takeaway
Kernels upstream novos (6.19, 7.0) têm pacotes NVIDIA no nixpkgs (open modules 595/610 para linux_7_0). A NVIDIA corrige builds para kernels novos via point releases. Kernels com patchsets (Zen/XanMod/CachyOS) são onde aparecem falhas de build do módulo, mas não achei lista consolidada de quebras recentes.

### Cited Findings
- nixpkgs expõe `linux_7_0.nvidia_x11_beta_open` (595.45.04) e `nvidia_x11_latest_open` (610.43.02), e há pacotes também para `linux_xanmod_stable` — [MyNixOS linux_7_0 latest_open](https://mynixos.com/nixpkgs/package/linuxKernel.packages.linux_7_0.nvidia_x11_latest_open), [MyNixOS xanmod_stable beta_open](https://mynixos.com/nixpkgs/package/linuxKernel.packages.linux_xanmod_stable.nvidia_x11_beta_open)
- NVIDIA lançou o 580.126.18 como driver recomendado com correção de build de módulo para Linux 6.19 — [PCGH](https://www.pcgameshardware.de/Grafikkarten-Grafikkarte-97980/News/Neuer-Linux-Grafiktreiber-von-Nvidia-1507283/)
- O ramo 580 é o último com Maxwell/Pascal/Volta; o 590 abandonou GTX 900/10; suporte do 580 previsto até cerca de jun/2028 — [KitGuru](https://www.kitguru.net/page/48/!https:/www.kitguru.net/components/graphic-cards/joao-silva/nvidia-drops-maxwell-and-pascal-support-with-new-linux-590-branch-drivers/), [negativo17](https://negativo17.org/nvidia-driver-580-lts-repository/)
- Exemplo de falha em kernel com patches: nvidia-open-dkms 575.57.08 falhou no XanMod 6.15.1 (objtool/RETHUNK) — [GitLab XanMod #439](https://gitlab.com/xanmod/linux/-/issues/439)
- Falhas históricas no NixOS: módulo NVIDIA quebrou com kernel 6.10 (funções implícitas) — [Discourse](https://discourse.nixos.org/t/unable-to-build-nix-due-to-nvidia-drivers-due-or-kernel-6-10/49266)
- Com o kernel CachyOS via Chaotic Nyx, relatou-se que definir apenas o pacote nvidia de `nvidiaPackages` do próprio kernel evita colisão; com `nix-cachyos-kernel` há relatos de conflito de driver — [Discourse](https://discourse.nixos.org/t/experimenting-with-cachyos-kernel-on-nixos-via-chaotics-nyx/70041). O README do nix-cachyos-kernel não trata NVIDIA — [GitHub](https://github.com/xddxdd/nix-cachyos-kernel)
- Chaotic Nyx foi arquivado em 8/12/2025; `xddxdd/nix-cachyos-kernel` é hoje o caminho principal — [resultado de busca / Chaotic Nyx](https://github.com/chaotic-cx/nyx)

### Inferences
- O kernel atual (6.18.55, LTS) é o mais seguro para NVIDIA: driver e nixpkgs já o cobrem. Saltar para 7.x ou para patchsets aumenta a chance de build quebrado após `flake update`/autoUpgrade, e o módulo é recompilado a cada kernel.
- O repo reescreve `flake.lock` no autoUpgrade (04:40, `operation=boot`): falha de build do módulo ali só impede o próximo boot atualizado, não o atual (boot generation antiga permanece).

### Gaps
- Tempo médio de correção no nixpkgs após quebra NVIDIA/kernel novo: não encontrei dado.
- Estado exato de `nvidiaPackages.stable/production` no nixpkgs de out/2026: não verificado (usar `nix eval` na máquina).
- Quebras específicas de 6.19/7.x com NVIDIA no NixOS: sem fonte.

## btrfs com patchsets e kernels novos

### Takeaway
Não achei relatos de que Zen/XanMod/CachyOS corrompam btrfs por seus patches. Há bugs upstream recentes (CVEs) corrigidos nas séries estáveis, então manter-se em série suportada e atualizada importa mais que o sabor do kernel.

### Cited Findings
- CVE-2026-46251 (corrupção da dirty_list do block group tree, com flag EXTENT_TREE_V2) afeta versões antes de 6.18.14, 6.19.4 e 7.0 — [CVE circl](https://cve.circl.lu/cve/CVE-2026-46251), [Red Hat Bugzilla](https://bugzilla.redhat.com/show_bug.cgi?id=2484466)
- CVE-2026-43046: bug de recuperação de relocation achado por fuzzing em 7.0-rc2-next — [LutraSecurity](https://fieldguide.lutrasecurity.com/CVE-2026-43046/)
- Houve pull request de fix btrfs para 7.0-rc7 — [LKML](https://lkml.iu.edu/hypermail/linux/kernel/2604.0/04010.html)

### Inferences
- A exposição ao CVE-2026-46251 exige EXTENT_TREE_V2 (experimental), improvável em btrfs comum.
- Um fork fora do ritmo do stable pode atrasar correções de btrfs; o 6.18.55 atual está bem acima de 6.18.14.

### Gaps
- Nenhuma fonte sobre issues btrfs específicos do CachyOS/Zen/XanMod. Ausência de evidência, não evidência de ausência.

## Ganhos medidos (BORE/EEVDF/sched_ext, CachyOS/Zen vs stock)

### Takeaway
Os ganhos medidos são pequenos e dependem do conjunto de testes. Os grandes números do CachyOS (distro) misturam kernel, compilador (-march/LTO), libs, Mesa e governors, e não isolam o kernel. A própria comparação de sabores de kernel do Phoronix aponta pouca diferença na maioria de cargas.

### Cited Findings
- Phoronix (jun/2026), sabores do kernel CachyOS: para muitas cargas de usuário limitadas por CPU (ex. Blender) não houve benefício significativo, e em muitos benchmarks gráficos pouca diferença — via snippet de busca; página 403 no fetch — [Phoronix](https://www.phoronix.com/review/cachyos-linux-flavors/5)
- Phoronix: a distro CachyOS ficou 3,5% acima do Ubuntu 26.04 e 4,3% acima do Fedora 44 em média geométrica (540,20 pontos); isso compara distros inteiras, não só kernel — [Phoronix](https://www.phoronix.com/review/cachyos-ubuntu-2604-fedora-44/5)
- Teste de sched_ext no Cyberpunk 2077 (Core Ultra 7 270K Plus + RX 9070 XT): scx_flash +1,37%, scx_lavd +0,78%, scx_bpfland +0,29% sobre EEVDF — [CachyOS forum, resultado de busca](https://discuss.cachyos.org/t/share-your-benchmarks/122). Fonte comunitária, n pequeno, hardware Intel+AMD GPU, sem barra de erro vista; trate como indicativo.
- scx_lavd (Igalia, 6.9-rc1) mostrou FPS médio e 1% low melhores ou similares ao EEVDF — [Phoronix](https://phoronix.com/news/LAVD-Scheduler-Linux-Gaming)
- Um relato de comunidade fala em cerca de 10% single-core e 8% multi-core no Geekbench com kernel CachyOS LTO — [Discourse](https://discourse.nixos.org/t/experimenting-with-cachyos-kernel-on-nixos-via-chaotics-nyx/70041). Anedótico; Geekbench não mede jogo.

### Inferences
- Para jogos limitados por GPU (NVIDIA), o ganho de scheduler fica em ordem de ~1% ou ruído. Efeito possível em 1% low/stutter com CPU saturada, não comprovado aqui.
- sched_ext (scx) pode ser testado sem trocar de kernel se o kernel tiver sched_ext habilitado; o linux 6.18 do nixpkgs normalmente tem (`services.scx` existe no NixOS), mas confirmar com `zcat /proc/config.gz | grep SCHED_CLASS_EXT`.

### Gaps
- Benchmarks independentes com NVIDIA + CPU AMD (Zen) comparando kernel nixpkgs vs CachyOS vs Zen no mesmo userspace: não encontrei.
- Números de latência (frametime p99) para Zen/XanMod vs stock em 2025-2026: não encontrei.

## Riscos: segurança, boot, rebuild, Secure Boot, anti-cheat, ntsync/fsync

### Takeaway
Os riscos principais são atraso de patches de segurança nos forks, rebuild do módulo NVIDIA e dos kernels fora do cache, e dependência de um flake de terceiros. Anti-cheat do Proton (EAC/BattlEye) roda em user mode, então não depende do kernel customizado. ntsync existe desde o 6.14 no mainline, então o kernel stock já serve.

### Cited Findings
- NTSYNC entrou habilitado no Linux 6.14; precisa de `CONFIG_NTSYNC` e `/dev/ntsync` com permissão — [Phoronix](https://www.phoronix.com/news/Linux-6.14-NTSYNC-Driver-Ready), [GamingOnLinux](https://www.gamingonlinux.com/2025/01/ntsync-for-proton-wine-now-in-linux-kernel-6-14-that-should-make-many-steamos-users-happy/page=1/)
- No Proton da Valve, fsync já é tão rápido ou mais que ntsync; o ganho grande do ntsync é no Wine puro — [GamingOnLinux](https://www.gamingonlinux.com/2025/03/linux-kernel-6-14-out-late-due-to-pure-incompetence-dont-get-too-excited-about-linux-gaming-boosts/page=1/), [CachyOS forum](https://discuss.cachyos.org/t/ntsync-in-latest-proton-cachyos-wine-cachyos/5254?page=2)
- Proton suporta EAC e BattlEye por título; no Linux eles são user-mode, sem acesso a kernel — [Steamworks](https://partner.steamgames.com/doc/steamdeck/proton), [Boiling Steam](https://boilingsteam.com/anticheat-support/). EAC exige Proton assinado, o que afeta Proton de terceiros, não o kernel
- nix-cachyos-kernel: overlay `pinned` casa com a revisão do nixpkgs para usar o cache binário (`attic.xuyh0120.win/lantian`); variantes LTS/latest/BORE/EEVDF/Hardened/RT/Server, níveis x86_64-v2/3/4 e Zen4; variantes LTO raras não ficam em cache; descompasso entre patches CachyOS e nixpkgs causa falhas de build até sincronizar — [GitHub](https://github.com/xddxdd/nix-cachyos-kernel)
- Lanzaboote assina kernel e initrd e gera UKI com stub próprio; o kernel customizado é assinado igual — [Lanzaboote](https://github.com/nix-community/lanzaboote). O README do nix-cachyos-kernel não menciona lanzaboote
- Tooling de terceiros é frágil: o Chaotic Nyx foi arquivado em dez/2025 — [Chaotic Nyx](https://github.com/chaotic-cx/nyx)

### Inferences
- Sem cache, compilar um kernel completo + módulo NVIDIA custa dezenas de minutos de CPU; com o overlay pinned isso é evitado, mas fixar o nixpkgs do flake no mesmo rev do cache pode conflitar com o `nixpkgs` do repo (`nixos-unstable` + autoUpgrade). Ponto de atenção real para este flake.
- Segurança: kernels de terceiros dependem do mantenedor para subir as versões estáveis; o kernel do nixpkgs acompanha o stable com latência curta (não medida aqui). O repo já faz autoUpgrade, então um fork lento atrasa tudo.
- O Secure Boot não é bloqueio, mas não há evidência no uso conjunto lanzaboote + cachyos-kernel + NVIDIA; testar com a geração antiga como rollback. Este repo não parece usar lanzaboote (não verificado).

### Gaps
- Latência real de patches de segurança do nixpkgs e dos forks: sem dado.
- Se o usuário usa Secure Boot hoje: não verifiquei (`bootctl status`).
- Confirmação de que EAC/BattlEye não rejeitam kernels customizados: apenas inferência a partir da natureza user-mode; sem relato direto.

## Recomendação e rollout seguro

### Takeaway
Para esta máquina (GPU NVIDIA, jogos bound por GPU, atualização automática), o benefício esperado de kernel customizado é pequeno (~1% medido em scheduler, ruído em muitos casos) e o custo de risco é real. Recomendação: manter o kernel stock do nixpkgs (6.18 LTS ou `linuxPackages_latest` se precisar de hardware novo), habilitar ntsync/sched_ext se desejado, e só experimentar CachyOS como especialização.

### Cited Findings
- Veja as seções anteriores; esta seção é síntese. Cache e overlay: [nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel).

### Inferences
- Ordem de preferência: (1) stock 6.18 LTS, com scx opcional (`services.scx.enable`, scx_lavd/bpfland) e `boot.kernelModules = [ "ntsync" ]` se o config tiver; (2) `linuxPackages_zen` do nixpkgs, que usa o pipeline de módulos do nixpkgs e tem pacote NVIDIA próprio; (3) `nix-cachyos-kernel` LTS (não "latest") com BORE, só se medir ganho.
- XanMod/CachyOS "latest" é o pior casamento com NVIDIA: kernel mais novo que o driver validado.
- Rollout: usar `specialisation` com o kernel alternativo (a geração padrão fica stock), testar primeiro com `nixos-rebuild build`/`boot` (não `switch`), manter `boot.loader.systemd-boot.configurationLimit` com gerações antigas, medir com MangoHud (1% low) em 2-3 jogos antes e depois, não deixar o autoUpgrade mover o kernel alternativo sem teste (fixar o input do kernel), e conferir `nvidia-smi` e `dmesg` após o boot.

### Gaps
- Não medi nada nesta máquina; todos os ganhos acima são de terceiros.
- Não verifiquei o estado atual do flake (versão do driver e do kernel em uso).
