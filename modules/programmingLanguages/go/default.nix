{ mode, config, pkgs, lib, soxin, ... }:

with lib;
let
  cfg = config.soxin.programmingLanguages.go;
in
{
  config = mkIf cfg.enable (mkMerge [
    {
      soxin.programmingLanguages.go = {
        vscode = {
          extensions = [ pkgs.vscode-extensions.golang.Go ];
        };
      };
    }

    (optionalAttrs (mode == "home-manager") {
      programs.go = {
        enable = true;
      };
    })
  ]);
}
