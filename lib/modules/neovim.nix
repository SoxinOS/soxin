{ nixpkgs, home-manager, ... }:

let
  inherit (nixpkgs) lib;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;

  hmModuleEval = home-manager.lib.homeManagerConfiguration rec {
    system="x86_64-linux";
    configuration = { };
    username = "nouser";
    homeDirectory="/home/nouser";
    pkgs = builtins.getAttr system nixpkgs.outputs.legacyPackages;
  };
in
{
  pluginWithConfigModule = hmModuleEval.options.programs.neovim.plugins.type;
}
