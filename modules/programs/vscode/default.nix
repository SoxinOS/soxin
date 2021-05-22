{ mode, config, pkgs, lib, soxin, ... }:

with lib;
let
  cfg = config.soxin.programs.vscode;
in
{
  options = {
    soxin.programs.vscode = soxin.lib.mkSoxinModule {
      inherit config;
      name = "vscode";
      includeProgrammingLanguage = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "home-manager") {
      programs.vscode = mkMerge [
        { inherit (cfg) enable; }
        cfg.programmingLanguages.extentions
      ];
    })
  ]);
}