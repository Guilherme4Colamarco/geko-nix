# Programas da faculdade: JDK 21, NetBeans e SQL Developer.
{ pkgs, ... }: {
  programs.java = { enable = true; package = pkgs.jdk21; };
  environment.systemPackages = [ pkgs.netbeans (pkgs.callPackage ../pkgs/sqldeveloper.nix {}) ];
}
