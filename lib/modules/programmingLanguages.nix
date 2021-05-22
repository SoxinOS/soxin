{ lib }:

let
  inherit (lib)
    mkOption
    types
    ;
in
rec {
  programmingLanguagesModule = types.submodule {
    options = {
      vscode = mkOption {
        type = vscodeModule;
        default = { };
      };
    };
  };

  vscodeModule = with types; submodule {
    options = {
       extensions = mkOption {
        type = types.nullOr (types.package);
        default = [ ];
        example = literalExample "[ pkgs.vscode-extensions.bbenoist.Nix ]";
        description = ''
          The extensions Visual Studio Code should be started with.
          These will override but not delete manually installed ones.
        '';
      };
    };
  };

}
