{ mode, config, pkgs, lib, soxin, ... }:

with lib;
{
  config.soxin.programmingLanguagesModules.go = (mkMerge [
    {
      vscode = {
        extensions = [ pkgs.vscode-extensions.golang.Go ];
      };
    }

    /*(optionalAttrs (mode == "home-manager") {
      programs.go = {
      enable = true;
      };
      })*/
  ]);
}
