{
  # hardware
  bluetooth = ./hardware/bluetooth.nix;

  # programs
  autorandr = ./programs/autorandr;
  git = ./programs/git;
  keybase = ./programs/keybase;
  less = ./programs/less;
  neovim = ./programs/neovim;
  rbrowser = ./programs/rbrowser;
  rofi = ./programs/rofi;
  starship = ./programs/starship;
  termite = ./programs/termite;
  tmux = ./programs/tmux;
  zsh = ./programs/zsh;
  vscode = ./programs/vscode;

  # settings
  settings = ./settings;
  # keyboard = ./settings/keyboard.nix;
  # theme = ./settings/theme.nix;
  # programmingLanguages = ./settings/programming-languages.nix;
  # tools = ./settings/tools.nix;

  # themes
  themes = ./themes;

  # programmingLanguages
  programmingLanguages = ./programming-languages;

  # tools
  tools = ./tools;
}
