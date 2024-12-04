{ lib, ... }:

let
  inherit (lib) mkMerge;
in
{
  config = mkMerge [ { soxin.programs.zsh.enable = true; } ];
}
