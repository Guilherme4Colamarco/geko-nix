# Software migration verification / Verificação da migração

Date / Data: 2026-10-06. Baseline: the working tree at the start of this task,
including its pre-existing uncommitted changes, not Git HEAD. / Base: árvore
de trabalho inicial, incluindo alterações anteriores não commitadas.

## Results / Resultados

| Verification / Verificação | Result / Resultado |
|---|---|
| Category evaluation / Avaliação das categorias | `checks.x86_64-linux.software`: disabled, isolated, combined, empty, duplicates, invalid app/Proton names, lazy extras, raw packages, all catalog entries, Flatpak union and integration gates |
| Personal configuration / Configuração pessoal | `checks.x86_64-linux.software-personal`: packages, Steam/Protons, controllers, optimizations, Docker, Java, AstroNvim, skills and desktop independence |
| Profiles / Perfis | `nixos`, `serpantinum`, `pleamar`, `niri`, `hyprland`: full toplevel derivation evaluation passed / avaliação completa passou |
| Full system build / Build completo | Serpantinum passed / passou; `nixos` is the same output / mesmo resultado |
| Lock | Byte-for-byte unchanged during this task / idêntico ao início da tarefa |
| Activation / Ativação | Not performed: `sudo -n true` reports that a password is required / não realizada: sudo exige senha |

The checks evaluate derivations; they do not build every optional application
or exercise games, audio capture, drivers or Flatpak downloads. The Serpantinum
build does build the personal selection. Existing upstream deprecation warnings
(`stdenv.isLinux`, `xorg.*`) did not prevent evaluation or build.

Os checks avaliam derivações; não constroem todos os aplicativos opcionais nem
testam jogos, captura de áudio, drivers ou downloads de Flatpak. O build do
Serpantinum constrói a seleção pessoal. Avisos upstream de depreciação
(`stdenv.isLinux`, `xorg.*`) não impediram avaliação ou build.

Lock SHA-256: `a460382919e7b5bda60f4d04c438d4a225ade40b5eca2c58d0cb41da2859a0a5`.
The lock already differed from HEAD before this task. / O lock já diferia do
HEAD antes desta tarefa.

## Before/after / Antes e depois

| Item | Comparison / Comparação |
|---|---|
| Explicit package output paths / Caminhos dos pacotes explícitos | 40 moved from system to Home Manager / 40 migraram do sistema para Home Manager |
| System packages / Pacotes do sistema | 200 → 159 unique outputs / saídas únicas |
| Home packages / Pacotes pessoais | 17 → 58 unique outputs / saídas únicas |
| Combined package set / Conjunto combinado | No application removed: only Neovim wrapper and generated HM session scripts changed / nenhum aplicativo removido; mudaram apenas wrapper do Neovim e scripts de sessão gerados pelo HM |
| Groups / Grupos | Same set: `networkmanager`, `wheel`, `i2c`, `docker`, `kvm` (order changed / ordem mudou) |
| TCP ports / Portas TCP | Unchanged / iguais: `27015`, `27036`, `27037` |
| UDP ports / Portas UDP | Unchanged / iguais: `10400`, `10401`, `27015`, `27036`; range / intervalo `27031–27035` |
| Kernel modules / Módulos de kernel | Same list, including controller and KVM modules / mesma lista, incluindo controles e KVM |
| System service names / Nomes dos serviços de sistema | Same 75 names / mesmos 75 nomes |
| Flatpak | Same system-wide Stremio entry / mesmo Stremio de sistema; unmanaged removal remains disabled / remoção de apps manuais continua desligada |
| Proton outputs / Saídas dos Protons | Exact same store paths / mesmos caminhos: GE-Proton11-7, DW-Proton 11.0-13, Proton-CachyOS 11.0-20260703-slr |

Neovim now uses the Home Manager wrapper; the underlying Neovim version and
AstroNvim template remain unchanged. The category manages the default editor
for the user. The personal `NVIM_APPNAME=astronvim` and `VISUAL=nvim` remain.
Direnv's handwritten Fish hook was replaced by Home Manager integration, with
nix-direnv added. Docker retains weekly pruning, logging and group access.
The personal checks also verify that disabling development removes its editor,
skill and Java configuration without removing desktop essentials.

Neovim agora usa o wrapper do Home Manager; sua versão e o template AstroNvim
continuam iguais. A categoria gerencia o editor padrão do usuário. As variáveis
pessoais `NVIM_APPNAME=astronvim` e `VISUAL=nvim` permanecem. O hook manual do
Fish para direnv foi substituído pela integração do Home Manager, com nix-direnv.
Docker mantém limpeza semanal, logs e acesso pelo grupo. Os checks pessoais
verificam também que desligar development remove suas configurações de editor,
skills e Java sem remover componentes necessários ao desktop.

The old `minecraft` and `ryujinx` entries fail in the locked Nixpkgs revision
and were removed from the catalog; neither was personally selected. All other
old gaming entries evaluated successfully without `allowBroken`.

As entradas antigas `minecraft` e `ryujinx` falham no Nixpkgs fixado e foram
removidas do catálogo; nenhuma fazia parte da seleção pessoal. As demais
entradas antigas avaliaram sem `allowBroken`.

## Built generation / Geração construída

Initial refactor output / Saída inicial da refatoração:

```
/nix/store/xhqdcc4m1yk9nzhna16r4vd0fhs1bydv-nixos-system-nixos-26.11.20261006.151fa4e
```

The initial output was subsequently activated by the user. The profile migration
below adds Vial to a newer `result-software`. To activate that built output,
from the repository directory / A saída inicial foi ativada posteriormente pelo
usuário. A migração abaixo adiciona Vial a um novo `result-software`. Para
ativar essa saída construída, na pasta do repositório:

```sh
sudo ./result-software/bin/switch-to-configuration test
sudo nix-env --profile /nix/var/nix/profiles/system --set "$(readlink -f result-software)"
sudo ./result-software/bin/switch-to-configuration switch
```

If testing fails, stop before the next commands and return to the boot-default
system with `sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test`.
After a successful switch, rollback is `sudo nixos-rebuild switch --rollback`.

Se o teste falhar, pare antes dos próximos comandos e retorne ao sistema padrão
de boot com `sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test`.
Após um switch bem-sucedido, use `sudo nixos-rebuild switch --rollback` para voltar.
These operations do not update the lock. / Essas operações não atualizam o lock.

## Repeat / Repetir

```sh
nix build --no-link --no-update-lock-file \
  .#checks.x86_64-linux.software .#checks.x86_64-linux.software-personal
nix eval --json --impure --expr '
  let f = builtins.getFlake (toString ./.);
  in builtins.mapAttrs (_: s: s.config.system.build.toplevel.drvPath)
    f.nixosConfigurations'
nix build --no-update-lock-file --out-link result-software \
  .#nixosConfigurations.serpantinum.config.system.build.toplevel
```

## User profile migration / Migração do perfil pessoal

The eight `nix profile` entries are now declared: Codex, fastfetch, fetch,
Heroic, NetBeans, Node.js, rmatrix and Vial. Seven were already available in
the active declarative generation and their imperative duplicates were removed.
Vial was added to `software.user.packages`; its imperative entry is retained
until the new system is activated. Build passed, lock unchanged.

As oito entradas do perfil estão declaradas. Sete já estavam disponíveis na
geração declarativa ativa e suas duplicatas imperativas foram removidas. Vial
foi acrescentado à lista pessoal e permanece no perfil até a nova ativação.
Build passou; lock preservado. A ativação por este agente exige senha de sudo.

Current / Atual `result-software`:

```
/nix/store/5jpqvbrzlzwjnfwd7x844i4w908i79yr-nixos-system-nixos-26.11.20261006.151fa4e
```

After successful activation / Após ativação bem-sucedida: `nix profile remove vial`.
