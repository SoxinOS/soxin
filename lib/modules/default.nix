{ lib }:

rec {
  keyboard = import ./keyboard.nix { inherit lib; };
  neovim = import ./neovim.nix { inherit lib; };
  themes = import ./themes.nix { inherit lib neovim zsh; };
  tmux = import ./tmux.nix { inherit lib; };
  zsh = import ./zsh.nix { inherit lib; };
}
