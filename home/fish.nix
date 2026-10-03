{ pkgs, ... }: {
  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ../config/fish/config.fish;
    plugins = map (name: { inherit name; src = pkgs.fishPlugins.${name}.src; }) [ "autopair-fish" "done" "fzf-fish" ];
    functions = {
      mkcd = "mkdir -p -- $argv; and cd -- $argv[-1]";
      y = ''
        set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        set -l cwd (cat -- "$tmp")
        if test -n "$cwd"; and test "$cwd" != "$PWD"
          builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      '';
    };
  };
  xdg.configFile."starship.toml".source = ../config/starship.toml;
}
