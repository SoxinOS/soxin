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
      includeProgrammingLanguages = true;
      includeTool = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "home-manager") {
      programs.vscode = mkMerge [
        { inherit (cfg) enable; }
        {
          extentions = flatten (mapAttrsToList (language: module:
            module.vscode.extenstions
          ) (filterAttrs (language: module: module.enable) cfg.programmingLanguages));
        }
      ];
    })
  ]);
}
