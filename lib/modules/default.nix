inputs@{ nixpkgs, ... }:

{
  keyboard = import ./keyboard.nix inputs;
  neovim = import ./neovim.nix inputs;
  programmingLanguages = import ./programmingLanguages.nix inputs;
  themes = import ./themes.nix inputs;
  tmux = import ./tmux.nix inputs;
  zsh = import ./zsh.nix inputs;
}
