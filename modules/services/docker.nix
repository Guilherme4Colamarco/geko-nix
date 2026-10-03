{ pkgs, ... }:

{
  # --- DOCKER ENGINE CONFIGURATION ---
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
    daemon.settings = {
      "log-driver" = "json-file";
      "log-opts" = {
        "max-size" = "10m";
        "max-file" = "3";
      };
      "live-restore" = true;
    };
  };

  # Add geko to docker group to run docker CLI without sudo
  users.users.geko.extraGroups = [ "docker" ];

  # Docker utils
  environment.systemPackages = with pkgs; [
    docker-compose
    lazydocker
    ctop
  ];

  # No containers or server stacks are started by this workstation profile.
}
