# Configuração de kernel customizado em flake NixOS, com caches binários

## 1. boot.kernelPackages com kernels do nixpkgs (zen, xanmod, lqx, latest)

### Takeaway
Basta atribuir `boot.kernelPackages = pkgs.linuxPackages_<variante>;`. Todos os módulos out-of-tree devem sair de `config.boot.kernelPackages`. Os kernels do nixpkgs vêm do cache oficial (cache.nixos.org) quando a variante é construída pelo Hydra; zen/xanmod/lqx nem sempre são.

### Cited Findings
- A wiki do NixOS lista `linuxPackages_latest`, `linuxPackages_zen`, `linuxPackages_xanmod` e `linuxPackages_lqx`, escolhidos via `boot.kernelPackages` — [NixOS Wiki: Linux kernel](https://wiki.nixos.org/wiki/Linux_kernel)
- A wiki recomenda pegar módulos extras de `config.boot.kernelPackages` para casar versão; módulos carregam por `boot.kernelModules` e se instalam via `boot.extraModulePackages` — [NixOS Wiki](https://wiki.nixos.org/wiki/Linux_kernel); [Manual NixOS](https://nixos.org/manual/nixos/unstable/#sec-kernel-config)
- `boot.kernelPatches` permite aplicar patches ao kernel — [NixOS Wiki](https://wiki.nixos.org/wiki/Linux_kernel)

Snippet (nomes de atributos confirmados pela wiki; o formato do módulo é padrão):
```nix
{ pkgs, ... }: {
  boot.kernelPackages = pkgs.linuxPackages_zen;   # ou _xanmod, _lqx, _latest
}
```

### Inferences
- Zen/xanmod/lqx são compilados a partir do mesmo nixpkgs que você trava no `flake.lock`; se o Hydra não os construiu naquela revisão, compila localmente (não verificado contra o Hydra, apenas inferência).

### Gaps
- Não verifiquei quais variantes (zen/xanmod/lqx) o cache.nixos.org cobre atualmente.

## 2. chaotic-nyx e xddxdd/nix-cachyos-kernel como inputs; nomes de atributos

### Takeaway
Dois caminhos. (a) xddxdd/nix-cachyos-kernel: input `release`, NÃO usar `follows` para nixpkgs, overlay `pinned`, atributo `pkgs.cachyosKernels.linuxPackages-cachyos-latest`. (b) chaotic-nyx: input `nyxpkgs-unstable`, sem `follows`, módulo `chaotic.nixosModules.default`, atributo `pkgs.linuxPackages_cachyos`.

### Cited Findings
**nix-cachyos-kernel**
- Input: `inputs.nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";`. O README manda não sobrescrever o nixpkgs do input, para evitar descasamento entre patches e binários — [README](https://github.com/xddxdd/nix-cachyos-kernel)
- Overlays: `pinned` (recomendado, usa o nixpkgs exato do flake, garante hits no cache) e `default` (usa o seu nixpkgs, pode causar cache miss) — [README](https://github.com/xddxdd/nix-cachyos-kernel)
- Nomes: `pkgs.cachyosKernels.linuxPackages-cachyos-{variante}[-lto][-cpu]`, variantes latest, lts, bore, bmq, deckify, eevdf, hardened, rc, rt-bore, server; CPU: x86_64-v2/v3/v4, zen4; `-lto` = Clang ThinLTO — [README raw](https://raw.githubusercontent.com/xddxdd/nix-cachyos-kernel/release/README.md)
- Alguns LTO (bmq-lto, deckify-lto, hardened-lto, outros marcados) NÃO têm cache binário — [README](https://github.com/xddxdd/nix-cachyos-kernel)
- Exemplo oficial (README):
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };
  outputs = { self, nixpkgs, nix-cachyos-kernel }: {
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, config, ... }: {
          nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];
          boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
        })
      ];
    };
  };
}
```
- O README diz para aplicar a config do cache uma vez (switch) ANTES de ligar o kernel — [README raw](https://raw.githubusercontent.com/xddxdd/nix-cachyos-kernel/release/README.md)
- Há um template `.override` (cpusched, lto, processorOpt, hzTicks, bbr3...) para kernel customizado — mesmo README raw.

**chaotic-nyx**
- Input: `chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";` — [README](https://github.com/chaotic-cx/nyx)
- Módulo: `chaotic.nixosModules.default` (unstable); em stable, três módulos separados `nyx-cache`, `nyx-overlay`, `nyx-registry` — [README raw](https://raw.githubusercontent.com/chaotic-cx/nyx/main/README.md)
- Kernel: `boot.kernelPackages = pkgs.linuxPackages_cachyos;` (também `cachyos-lts`, `cachyos-hardened`, `cachyos-rc`, `cachyos-server`, `cachyos-lto-znver4`; grafia exata dos sufixos conforme resumo do README, conferir no repositório) — [README](https://github.com/chaotic-cx/nyx)
- `inputs.nixpkgs.follows` no chaotic causa hash diferente (cache miss); o README manda remover — [README raw](https://raw.githubusercontent.com/chaotic-cx/nyx/main/README.md)

Snippet chaotic (montado a partir do README; a junção em `modules` não foi testada):
```nix
inputs.chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";   # sem follows
# modules = [ chaotic.nixosModules.default ({ pkgs, ... }: {
#   boot.kernelPackages = pkgs.linuxPackages_cachyos;
# }) ];
```

### Inferences
- Os dois projetos são alternativas; não combinar. Para esta máquina (nixos-unstable + NVIDIA), o nix-cachyos-kernel com overlay `pinned` é o caminho mais simples, mas ver seção 4 sobre NVIDIA.
- Este repositório pina `nixpkgs` próprio; com `pinned`, o kernel vem do nixpkgs do input deles, e módulos out-of-tree (NVIDIA etc.) vêm do SEU nixpkgs, o que pode gerar descasamento de versão de API do kernel (inferência, não verificada).

### Gaps
- Não confirmei a existência atual do atributo `overlays.pinned` fora do README (confiei nele). Não li o flake.nix do chaotic para a lista exata de atributos.

## 3. Caches binários e o que acontece em cache miss

### Takeaway
nix-cachyos-kernel: `https://attic.xuyh0120.win/lantian` com chave `lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=`. chaotic: `https://nyx-cache.chaotic.cx/` com chave `nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk=`. Em cache miss, o kernel compila localmente (horas).

### Cited Findings
- Config manual do nix-cachyos-kernel:
```nix
nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
```
  O flake também declara via `nixConfig` (aceitar com `--accept-flake-config` ou `nixConfig` no seu flake; exige usuário confiável) — [README](https://github.com/xddxdd/nix-cachyos-kernel)
- chaotic: cache adicionado automaticamente pelo módulo default; desligar com `chaotic.nyx.cache.enable = false;` — [README](https://github.com/chaotic-cx/nyx)
- Depuração de miss no chaotic: comparar o caminho de saída pelos três métodos de avaliação, checar `/etc/nix/nix.conf`, reiniciar nix-daemon, testar o narinfo com curl — [README raw](https://raw.githubusercontent.com/chaotic-cx/nyx/main/README.md)
- Falhas de build dos CachyOS costumam vir de descasamento entre patches e versão do kernel do nixpkgs — [README](https://github.com/xddxdd/nix-cachyos-kernel)
- O README do nix-cachyos-kernel diz que o repositório atualiza diariamente por GitHub Actions — [README](https://github.com/xddxdd/nix-cachyos-kernel)

### Inferences
- Qualquer mudança que altere o derivation (follows, overlay `default`, override de argumentos, outro nixpkgs, outro compilador) muda o hash de saída e causa miss; um kernel compila por muito tempo (horas é o consenso geral; não medi).
- Mitigação prática: aplicar os substituters com `nixos-rebuild switch` antes; testar com `nix build --dry-run` e ver "will be built" vs "will be fetched" antes de trocar o kernel; usar `--max-jobs`/não rodar no autoUpgrade sem checar (o autoUpgrade deste repo reescreve o lock, então pode puxar um rev sem cache ainda).

### Gaps
- Não consegui abrir as páginas do cachix/attic para confirmar retenção, nem verificar se a chave do chaotic ainda é a vigente em out/2026 além do README.

## 4. Módulos out-of-tree (NVIDIA, v4l2loopback), rebuild e fallback

### Takeaway
Módulos out-of-tree são recompilados contra o kernel escolhido (via `config.boot.kernelPackages.*`) em cada rebuild; com kernel customizado eles NÃO vêm do cache do kernel e podem precisar de compilação local. O fallback é uma `specialisation` ou manter gerações antigas no menu do bootloader.

### Cited Findings
- Módulos devem casar versão com o kernel: usar `config.boot.kernelPackages` — [NixOS Wiki](https://wiki.nixos.org/wiki/Linux_kernel)
- Exemplo de ZFS no README do nix-cachyos-kernel: `boot.zfs.package = config.boot.kernelPackages.zfs_cachyos;`; aviso de que o ZFS pode falhar por incompatibilidade de kernel — [README raw](https://raw.githubusercontent.com/xddxdd/nix-cachyos-kernel/release/README.md)
- Issue aberta (sem resolução na leitura): com nix-cachyos-kernel 6.18.0, NVIDIA 590.44.01 (`nvidiaPackages.beta`) falhou ("NVRM: The NVIDIA probe routine was not called", outro driver tomou o dispositivo), enquanto a versão do chaotic-nyx funcionou — [Issue #13](https://github.com/xddxdd/nix-cachyos-kernel/issues/13)
- Specialisations criam perfis de boot alternativos (confirmado no contexto de NVIDIA) — [Discourse](https://discourse.nixos.org/t/proprietary-nvidia-specialisation/74704)

Snippet de fallback (NÃO verificado em fonte primária; uso padrão de `specialisation`/`lib.mkForce`, deve ser testado com `nixos-rebuild build`):
```nix
{ pkgs, lib, ... }: {
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  specialisation.kernel-padrao.configuration = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages;   # kernel stock do nixpkgs
  };
}
```
Observação: o kernel stock fica como entrada separada no menu; o `pkgs.linuxPackages` com overlay pode ser o do overlay, conferir.

### Inferences
- O kernel stock em specialisation também evita ficar sem rede/gráficos se o módulo NVIDIA falhar no CachyOS. Dado o issue #13, para esta máquina com NVIDIA, a specialisation é recomendada; alternativamente `boot.loader.systemd-boot.configurationLimit` mantém gerações antigas (inferência, não pesquisei).
- Rebuild dos módulos: acontece automaticamente com `nixos-rebuild`; para forçar, `nix build` do toplevel e olhar o que será construído.

### Gaps
- Nada verificado sobre v4l2loopback especificamente com kernels CachyOS (nenhuma fonte encontrada). Nada verificado sobre `hardware.nvidia.open` com esses kernels além do issue acima.

## 5. sched_ext / scx no NixOS com kernels CachyOS

### Takeaway
Use `services.scx.enable = true;` (módulo do nixpkgs); exige kernel >= 6.12 com sched_ext, o que os kernels CachyOS têm.

### Cited Findings
- Opções: `enable`, `package` (padrão `pkgs.scx.full`; alternativa `pkgs.scx.rustscheds`), `scheduler` (padrão `"scx_rustland"`), `extraArgs` — [nixpkgs scx.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/nixos/modules/services/scheduling/scx.nix)
- Assertion: "SCX is only supported on kernel version >= 6.12"; o serviço só inicia se existir `/sys/kernel/sched_ext` — mesma fonte
- O README do chaotic cita `services.scx.enable = true;` e `services.scx.scheduler = "scx_rusty";` — [README](https://github.com/chaotic-cx/nyx)

```nix
services.scx = {
  enable = true;
  scheduler = "scx_rusty";   # ou scx_lavd, scx_bpfland etc. (nomes conforme pacote)
  extraArgs = [ ];
};
```

### Inferences
- O kernel zen/xanmod/lqx do nixpkgs pode não habilitar sched_ext; o CachyOS habilita (suposição não verificada — verificar `ls /sys/kernel/sched_ext` após boot).
- Antes: o chaotic tinha opção própria `chaotic.scx`; hoje o README usa o `services.scx` padrão.

### Gaps
- Não verifiquei quais schedulers existem no `pkgs.scx.full` atual nem se `scx_rustland` ainda é o padrão em out/2026 (li o master do nixpkgs via fetch resumido).
