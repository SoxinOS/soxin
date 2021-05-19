{ mode, config, pkgs, lib, ... }:

with lib;
let
  cfg = config.soxin.programs.autorandr;
in
{
  options = {
    soxin.programs.autorandr = {
      enable = mkEnableOption ''
        the handling of hotplug and sleep events by autorandr.</para><para>
        It also enables the autorandr program on home-manager. It's recommended
        to configure the autorandr profiles following <link
        xlink:href="https://nix-community.github.io/home-manager/options.html#opt-programs.autorandr.profiles">the
        documentation on the home-manager manual</link>
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "NixOS") { services.autorandr.enable = true; })
    (optionalAttrs (mode == "home-manager") { programs.autorandr.enable = true; })
  ]);
}
