{ nixpkgs, home-manager, ... }:

let
  inherit (nixpkgs) lib;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;

  hmModuleEval = home-manager.homeManagerConfiguration {
    configuration = { };
    username = "foo";
    pkgs = nixpkgs;
    check = false;
  };
in
{
  pluginWithConfigModule = hmModuleEval.options.programs.neovim.plugins.type;
}
