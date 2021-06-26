{ nixpkgs, ... }@inputs:

let
  inherit (nixpkgs) lib;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;
in
rec {
  programmingLanguagesModule = types.submodule ({ name, ... }: {
    options = {
      # enable = mkEnableOption "Enable ${name} support.";

      vscode = mkOption {
        type = vscodeModule;
        default = { };
      };
    };
  });

  vscodeModule = with types; submodule {
    options = {
       extensions = mkOption {
        type = types.listOf types.package;
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
