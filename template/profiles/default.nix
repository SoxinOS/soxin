builtins.mapAttrs (_: moduleFile: import moduleFile) (import ./list.nix)
