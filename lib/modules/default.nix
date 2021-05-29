inputs@{ nixpkgs, ... }:

{
  keyboard = import ./keyboard.nix inputs;
  neovim = import ./neovim.nix inputs;
  themes = import ./themes.nix inputs;
  tmux = import ./tmux.nix inputs;
  zsh = import ./zsh.nix inputs;
}
