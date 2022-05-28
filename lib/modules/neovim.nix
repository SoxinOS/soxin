{ nixpkgs, home-manager, ... }:

let
  inherit (nixpkgs) lib;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;

  hmModuleEval =
    let
      # system don't matter here, we just need the type of the plugins option.
      system = "x86_64-linux";

      # username also don't matter here.
      username = "nobody";
    in
    home-manager.lib.homeManagerConfiguration {
      inherit system username;
      configuration = { };
      homeDirectory = "/home/${username}";
      pkgs = builtins.getAttr system nixpkgs.outputs.legacyPackages;
    };
in
{ pluginWithConfigModule = hmModuleEval.options.programs.neovim.plugins.type; }
