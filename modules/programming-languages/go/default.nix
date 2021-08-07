{ mode, config, pkgs, lib, soxin, ... }:

with lib;
{
  config.soxin.programmingLanguagesModules.go = (mkMerge [
    {
      vscode = {
        extensions = [ pkgs.vscode-extensions.golang.Go ];
      };
    }

  ]);
}
