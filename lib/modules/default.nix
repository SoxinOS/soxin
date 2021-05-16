{ lib }:

rec {
  keyboard = import ./keyboard.nix { inherit lib; };
  neovim = import ./neovim.nix { inherit lib; };
  themes = import ./themes.nix { inherit lib neovim zsh; };
  zsh = import ./zsh.nix { inherit lib; };
}
