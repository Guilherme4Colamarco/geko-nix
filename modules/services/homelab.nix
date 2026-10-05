# Modo servidor caseiro: acesso remoto por Tailscale (VPN) + SSH.
#
# Vem DESLIGADO. Quem usa só como desktop não expõe nada na rede.
# Para ligar, no host (ex.: configuration.nix ou um local.nix):
#
#   geko.homelab.enable = true;
#   geko.homelab.ssh.authorizedKeys = [ "ssh-ed25519 AAAA... voce@aparelho" ];
#
# Depois do primeiro switch, entre na sua conta Tailscale uma única vez:
#
#   sudo tailscale up
#
# e, de outro aparelho do mesmo tailnet:  ssh <usuario>@<nome-da-maquina>
#
# SSH é só por chave (sem senha, sem root). Sem nenhuma chave declarada ninguém
# consegue entrar; por isso há um aviso na construção. Esse módulo usa o usuário
# `geko` como o resto do repositório.
{ config, lib, pkgs, ... }:
let
  cfg = config.geko.homelab;
in {
  options.geko.homelab = {
    enable = lib.mkEnableOption "modo servidor caseiro (Tailscale + SSH)";

    tailscale.trustInterface = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Confia em tudo que chega pela interface tailscale0: o firewall deixa
        passar qualquer porta de qualquer aparelho do tailnet. Deixe desligado
        para liberar só o SSH pela VPN (o padrão).
      '';
    };

    ssh = {
      authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "ssh-ed25519 AAAAC3... voce@notebook" ];
        description = "Chaves públicas que podem entrar por SSH como geko.";
      };
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Abre a porta 22 em todas as interfaces (rede local e internet).
          Desligado, o SSH só responde pela VPN (tailscale0).
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;

    services.openssh = {
      enable = true;
      openFirewall = cfg.ssh.openFirewall;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    users.users.${config.geko.usuario.nome}.openssh.authorizedKeys.keys = cfg.ssh.authorizedKeys;

    networking.firewall = if cfg.tailscale.trustInterface
      then { trustedInterfaces = [ "tailscale0" ]; }
      else { interfaces.tailscale0.allowedTCPPorts = [ 22 ]; };

    environment.systemPackages = [ pkgs.tailscale pkgs.wakeonlan ];

    warnings = lib.optional (cfg.ssh.authorizedKeys == [ ])
      "geko.homelab.enable está ligado sem geko.homelab.ssh.authorizedKeys: o SSH só aceita chave, então ninguém conseguirá entrar.";
  };
}
