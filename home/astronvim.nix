# Personal AstroNvim template, kept separate from the reusable category.
{
  inputs,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = osConfig.software.development;
in
{
  config = lib.mkIf (cfg.enable && builtins.elem "neovim" cfg.apps) {
    xdg.configFile."astronvim".source = pkgs.runCommand "astronvim-config" { } ''
      cp -r ${inputs.astrovim} $out
      chmod -R u+w $out
      substituteInPlace $out/lua/lazy_setup.lua --replace-fail 'ui = { backdrop = 100 },' 'lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json", ui = { backdrop = 100 },'
    '';
  };
}
