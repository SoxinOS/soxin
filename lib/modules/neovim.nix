{ nixpkgs, home-manager, ... }:

let
  inherit (nixpkgs) lib;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;

  hmModuleEval = home-manager.lib.homeManagerConfiguration {
    system = "x86_64-linux"; # system don't matter here, we just need the type of the plugins option.
    configuration = { };
    username = "nouser";
    homeDirectory = "/home/nouser";
    pkgs = builtins.getAttr system nixpkgs.outputs.legacyPackages;
  };
in
{ pluginWithConfigModule = hmModuleEval.options.programs.neovim.plugins.type; }
