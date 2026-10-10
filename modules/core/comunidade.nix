# Repositórios da comunidade: NUR (pacotes de usuários, via pkgs.nur.repos.<autor>.<pacote>),
# nix-index-database (índice pronto para o comma e o command-not-found) e o cache
# binário do nix-community (evita compilar pacotes desses projetos).
{ inputs, ... }:
{
  imports = [ inputs.nix-index-database.nixosModules.nix-index ];

  nixpkgs.overlays = [ inputs.nur.overlays.default ];

  programs.nix-index-database.comma.enable = true;
  programs.command-not-found.enable = false;

  nix.settings = {
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
}
