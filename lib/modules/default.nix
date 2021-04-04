{ lib }:

{
  keyboard = import ./keyboard.nix { inherit lib; };

  themes = import ./themes.nix { inherit lib; };
}
