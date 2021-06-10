{ mode, config, pkgs, lib, soxin, ... }:

with lib;
let
  cfg = config.soxin.programmingLanguages.go;
in
{
  options = {
    soxin.programmingLanguages.go = {
      enable = mkEnableOption "Enable go programming language";
    };
  };

  cfg = {
    vscode = {
      extensions = [
        pkgs.vscode-extensions.golang.Go
      ];
    };
  };
  
  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "home-manager") {
      programs.go = {
        enable = true;
      }
    })
  ]);
}