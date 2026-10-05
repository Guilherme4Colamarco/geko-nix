{ pkgs, ... }:

{
  # Declarative core development toolchain. nodejs includes npm.
  environment.systemPackages = with pkgs; [
    gh
    nodejs
    python3
    uv
    ripgrep
    ffmpeg
    gcc
    gnumake
    pkg-config
    cmake
    ninja
  ];
}
