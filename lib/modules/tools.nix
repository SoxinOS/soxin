{ lib }:

let
  inherit (lib)
    mkOption
    types
    ;
in
rec {
  toolsModule = types.submodule {
    options = {
      
    };
  };
}
