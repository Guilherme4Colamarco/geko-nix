{ pkgs }:
let
  # DW-Proton and Proton-CachyOS are not packaged in this nixos-unstable
  # revision. Pin their official Steam Runtime releases here instead.
  protonRelease =
    {
      pname,
      version,
      url,
      hash,
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;
      src = pkgs.fetchurl { inherit url hash; };
      outputs = [
        "out"
        "steamcompattool"
      ];
      dontUnpack = true;
      installPhase = ''
        mkdir -p "$steamcompattool"
        tar -xJf "$src" --strip-components=1 -C "$steamcompattool"
        echo "Use programs.steam.extraCompatPackages" > "$out"
      '';
    };

  dwproton = protonRelease {
    pname = "dwproton";
    version = "11.0-13";
    url = "https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-11.0-13/dwproton-11.0-13-x86_64.tar.xz";
    hash = "sha512-dnsQXRgJPA+4cXsdblQKbO7jrV8zdkkbqo6PlQfaHwC0p4qI0KRoGB5bry5UBs4hb8IqUE+2YkC0qzfoUp/5MA==";
  };

  proton-cachyos = protonRelease {
    pname = "proton-cachyos";
    version = "11.0-20260703-slr";
    url = "https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-11.0-20260703-slr/proton-cachyos-11.0-20260703-slr-x86_64.tar.xz";
    hash = "sha512-cT/gCNZ+NJGu87Wx2a4sES18K1iz8j/COH0RIvwTH/fn8OonxnvyeXPZBr3OYjXDQJhTDsTHhgWUOLFTxuFhhw==";
  };

in
{
  ge = pkgs.proton-ge-bin;
  dw = dwproton;
  cachyos = proton-cachyos;
}
