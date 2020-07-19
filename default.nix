{ lib, }:

let
  soxinConfig = lib.evalModules {
    modules = [
      ./modules
    ];
  };

  options = builtins.removeAttrs soxinConfig.options [ "_module" ];
  nixos = soxinConfig.config.nixos.config;
  home-manager = soxinConfig.config.home-manager.config;
in {
  nixos = {
    inherit options;
    config = nixos;
  };

  home-manager = {
    inherit options;
    config = home-manager;
  };
}
