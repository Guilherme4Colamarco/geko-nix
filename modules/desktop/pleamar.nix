{ ... }: {
  programs.pleamar-wm = { enable = true; withMarea = true; };
  services.displayManager.defaultSession = "pleamar-wm";
  services.gnome.gnome-keyring.enable = true;
  services.upower.enable = true;
  # A sessão upstream inicia Marea. Nenhum serviço QS é importado aqui.
}
