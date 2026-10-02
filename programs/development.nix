{ pkgs, ... }:

{
  # Declarative core development toolchain. nodejs includes npm.
  environment.systemPackages = with pkgs; [
    git
    gh
    nodejs
    python3
    uv
    ripgrep
    fd
    jq
    ffmpeg
    gcc
    gnumake
    pkg-config
    cmake
    ninja
  ];
}
