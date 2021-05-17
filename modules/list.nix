{
  keyboard = ./settings/keyboard.nix;
  theme = ./settings/theme.nix;

  themes = ./themes;

  bluetooth = ./hardware/bluetooth.nix;

  neovim = ./programs/neovim;
  rbrowser = ./programs/rbrowser;
  rofi = ./programs/rofi;
  termite = ./programs/termite;
  tmux = ./programs/tmux;
  zsh = ./programs/zsh;
}
