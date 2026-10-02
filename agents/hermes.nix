{ pkgs, hermesAgent, ... }:

let
  agent = hermesAgent.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  # Bot Screen runs an Xvnc/Xfce desktop; the other Xfce tools are already
  # present through the configured fallback desktop session.
  environment.systemPackages = [ pkgs.tigervnc pkgs.xdpyinfo ];

  # Keep the messaging gateway on the same backend revision as Hermes Desktop.
  # The desktop package is installed by Ryoku through the unified flake input.
  systemd.user.services.hermes-agent = {
    description = "Hermes Agent Gateway";
    wantedBy = [ "default.target" ];
    after = [ "default.target" ];
    path = [ agent ];
    environment = {
      HERMES_HOME = "/home/geko/.hermes";
      HERMES_SUPERVISED_CHILD = "1";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${agent}/bin/hermes gateway run";
      WorkingDirectory = "/home/geko/.hermes";
      Restart = "always";
      RestartSec = 5;
      RestartForceExitStatus = 75;
      RestartPreventExitStatus = 78;
      SuccessExitStatus = 75;
      KillMode = "mixed";
      KillSignal = "SIGTERM";
      TimeoutStopSec = 70;
    };
  };
}
