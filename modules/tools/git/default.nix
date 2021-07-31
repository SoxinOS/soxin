{ mode, config, pkgs, lib, soxin, ... }:

with lib;
{
  config.soxin.toolsModules.git = (mkMerge [
    {
      vscode = {
        extensions = [ pkgs.vscode-extensions.eamodio.gitlens ];
      };
    }

    /*(optionalAttrs (mode == "home-manager") {
      programs.go = {
      enable = true;
      };
      })*/
  ]);
}
