{ inputs, pkgs, ... }: {
  imports = [ ./fish.nix ./claude-code.nix ];
  home.username = "geko";
  home.homeDirectory = "/home/geko";
  home.stateVersion = "26.05";
  home.packages = [ pkgs.mcp-nixos ];
  xdg.enable = true;
  xdg.configFile."astronvim".source = pkgs.runCommand "astronvim-config" {} ''
    cp -r ${inputs.astrovim} $out
    chmod -R u+w $out
    substituteInPlace $out/lua/lazy_setup.lua --replace-fail 'ui = { backdrop = 100 },' 'lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json", ui = { backdrop = 100 },'
  '';
}
