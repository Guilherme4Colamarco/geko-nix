# Software by use

[Guia equivalente em português](software.pt-BR.md).

Edit **`programs/user.nix`**. All Nixpkgs packages use the locked
`nixos-unstable` input; external flakes, SQL Developer and custom Protons keep
their pins and hashes. There is no stable/unstable application split.

## Starter configuration

This is a starter example, not geko's personal selection:

```nix
{ pkgs, ... }: {
  software = {
    user.packages = with pkgs; [ brave-origin obsidian ];
    flatpak.packages = [ "com.stremio.Stremio" ];
    gaming = {
      enable = true;
      apps = [ "steam" "heroic" "prism" "mangohud" ];
      controllers.enable = false;
      optimizations.enable = false;
      steam.remotePlay.enable = false;
      steam.dedicatedServer.enable = false;
      proton = [ "ge" ];
    };
    office.enable = false;
    development = {
      enable = true;
      apps = [ "neovim" "nodejs" "python" "build-tools" ];
      docker.enable = false;
    };
    studio.enable = false;
  };
}
```

Every category defaults to `enable = false`. Enabling it without `apps` uses
the starter set below. An explicit `apps` list replaces that set; `apps = []`
lets you use only integrations or `extraPackages`. Duplicate selections are
resolved once. Unknown names fail evaluation and report accepted values.
Unselected package entries are lazy: they do not evaluate or install dependencies.

`software.user.packages` installs ordinary Home Manager packages without
configuring them. For example, adding `pkgs.neovim` does not enable the category's
editor configuration. Every category also accepts `extraPackages = with pkgs;
[ hello ];`, installed only when that category is enabled. These lists merge
across Nix modules; use `lib.mkForce` if deliberately overriding another
module's explicit list. For normal edits, replace the list in `user.nix`.

## Catalog

The names below are the literal strings for `apps`.

| Category | Starter set | Additional selections |
|---|---|---|
| Gaming | `steam`, `heroic`, `prism`, `mangohud` | `hydra`, `lutris`, `bottles`, `itch`, `sober`, `roblox` (Sober alias), `lunar`, `bedrock`, `modrinth`, `atlauncher`, `gdlauncher`, `badlion`, `pcsx2`, `rpcs3`, `dolphin`, `retroarch`, `ppsspp`, `dualsensectl`, `protonup-qt`, `protontricks`, `goverlay` |
| Office | `libreoffice`, `evince`, `thunderbird` | `onlyoffice`, `obsidian`, `zotero` |
| Development | `neovim`, `gh`, `nodejs`, `python`, `build-tools`, `nix-tools`, `direnv` | `vscodium`, `cursor`, `antigravity-ide`, `antigravity-cli`, `codex`, `claude-code`, `jdk21`, `netbeans`, `sqldeveloper`, `dbeaver`, `go`, `rust` |
| Studio | `krita`, `inkscape`, `kdenlive`, `obs-studio`, `audacity`, `blender` | `gimp`, `darktable`, `shotcut`, `ardour` |

All old gaming entries were evaluated individually against the existing lock.
`minecraft` was removed from Nixpkgs because it was broken (use `prism`).
`ryujinx` was removed in favor of upstream `ryubing`; it is not part of this
catalog. Neither unavailable entry is accepted; `allowBroken` is not enabled.
The remaining old entries passed derivation evaluation, not runtime testing.

## Integrations and dependencies

- **Gaming:** `steam` enables the NixOS Steam module, rather than a second user
  copy. `proton` defaults to `[ "ge" ]`; `dw` and `cachyos` retain the exact
  versions and hashes in `programs/proton.nix`. `[]` disables extra Protons.
  Protons and Steam ports only apply when Steam is selected.
  `controllers.enable` enables xone, xpadneo and DualSense udev rules.
  `optimizations.enable` enables GameMode and Gamescope (plus its Steam session
  when Steam is selected). These switches and both firewall switches default
  to false. Disabling gaming gates all of them. GPU/display drivers remain
  in `modules/hardware/`, independent of gaming.
- **Development:** `python` adds Python and uv; `nodejs` includes npm;
  `build-tools` adds GCC, Make, CMake, Ninja and pkg-config; `nix-tools` adds
  nixd, nixfmt, ShellCheck and shfmt. `direnv` enables Home Manager shell
  integration and nix-direnv. `rust` uses Nixpkgs rustc and Cargo, not rustup.
  `jdk21` enables NixOS Java with JDK 21. SQL Developer has its own JDK 17.
  Neovim is configured through Home Manager and becomes the user's editor.
- **Docker:** `development.docker.enable` requires development enabled. It
  enables Docker Engine, the Docker group, Compose, lazydocker and ctop. The
  group grants administrator-equivalent access. Existing weekly pruning of
  unused Docker images (`--all`) and logging settings are retained; no
  containers or stacks are declared or automatically started by this category.
- **Studio:** OBS uses Home Manager with `obs-pipewire-audio-capture`, without
  a second OBS package in the category. Kdenlive, OBS, Audacity, Blender,
  Shotcut and Ardour also add FFmpeg.
- **Office:** normal desktop application integration; no forced accounts,
  file associations or language settings.

## Flatpaks and personal settings

`software.flatpak.packages` contains Flathub IDs. Sober/Roblox and Modrinth
contribute their IDs automatically. `programs/flatpak.nix` deduplicates the
combined list and enables Flatpak only when it is nonempty. The NixOS module
keeps the existing **system-wide installation**; CLI wrappers use that Flatpak.
`uninstallUnmanaged = false` and `uninstallUnused = false` preserve manual
applications and remotes. Removing a selection does not purge its data or
uninstall an existing Flatpak. Empty lists disable managed support, not delete
the installation. Flatpak installation happens on activation and needs network
access; a Nix build does not download or test those applications. See
[nix-flatpak's behavior](https://github.com/gmodena/nix-flatpak/blob/main/README.md).

Geko's explicit selection preserves Docker, controller drivers, gaming
optimizations, both Steam firewall integrations and all three Protons. Office
and studio start disabled; Obsidian and FFmpeg stay in the personal package list.
Personal AstroNvim and Claude Code skills are imported by `programs/user.nix`
and gated by the corresponding development selections. They are not category
defaults for another user. Claude Desktop and its Cowork KVM integration also
remain personal. Identity, locale, keyboard and disks are unchanged.
Desktop essentials (keyring, monitor brightness, GPU drivers, compositor
runtime dependencies) stay outside optional categories.

## Edit, verify, apply, roll back

```sh
# Edit programs/user.nix, then expose any NEW module files to the flake:
git add -N path/to/new-module.nix
nix build --no-link .#checks.x86_64-linux.software .#checks.x86_64-linux.software-personal --no-update-lock-file
nix build .#nixosConfigurations.serpantinum.config.system.build.toplevel \
  --no-update-lock-file --out-link result-software
# Activate exactly the generation you just built:
sudo ./result-software/bin/switch-to-configuration test
sudo nix-env --profile /nix/var/nix/profiles/system --set "$(readlink -f result-software)"
sudo ./result-software/bin/switch-to-configuration switch
# If necessary, restore the previous system generation:
sudo nixos-rebuild switch --rollback
```

Replace `serpantinum` with `nixos`, `niri`, `hyprland` or `pleamar` as needed.
A build is not activation. `test` changes the running session but not the boot
default. `switch` records the generation for subsequent boots. Rollback restores
the previous declared system, not mutable application data or Flatpak versions.
The Home Manager backup suffix is `before-geko-nix`; an existing conflicting
backup can block activation. Never delete personal data to resolve a conflict.
Do not update `flake.lock` as part of this refactor; channel upgrades are separate.

The `software` check covers disabled, isolated, combined, empty, duplicate and
invalid selections, optional integrations, Flatpak union, and every catalog
entry's derivation. See [migration verification](software-validation.md) for
profile builds and the personal before/after comparison.

## Module map

`programs/default.nix` imports `user.nix`, `flatpak.nix` and the four categories.
`category.nix` defines their common option schema; `proton.nix` holds fixed
releases. `modules/services/docker.nix` is imported by development and gated by
its switches. Reusable consumers may disable the personal module with
`disabledModules = [ ./programs/user.nix ];` (use the path relative to your file)
and supply their own `software` definitions. The old `mySystem.gaming` namespace
and stable/unstable/faculdade modules no longer exist. New category keys belong
in the category's lazy catalog and in both language guides.
