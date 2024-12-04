{
  mode,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.services.bogus;
in
{
  options = {
    services.bogus = {
      enable = mkEnableOption "bogus module.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "NixOS") {
      # Do something for NixOS configuration
    })

    (optionalAttrs (mode == "home-manager") {
      # Do something else for home-manager configuration
    })
  ]);
}
