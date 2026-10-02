{
  description = "Hermes Desktop e seu backend, em uma unica revisao";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.hermesAgent.url = "github:NousResearch/hermes-agent";

  outputs = { nixpkgs, hermesAgent, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      agent = hermesAgent.packages.${system}.default;
      desktop = hermesAgent.packages.${system}.desktop;
    in {
      packages.${system}.default = pkgs.symlinkJoin {
        name = "hermes-desktop-unified";
        paths = [ desktop agent ];
        meta.mainProgram = "hermes-desktop";
      };
    };
}
