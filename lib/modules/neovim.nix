{ nixpkgs, home-manager, ... }:

let
  inherit (nixpkgs) lib;
  inherit (lib) mkEnableOption mkOption types;

  hmModuleEval =
    let
      # system don't matter here, we just need the type of the plugins option.
      system = "x86_64-linux";

      # username also don't matter here.
      username = "nobody";
    in
    home-manager.lib.homeManagerConfiguration {
      pkgs = builtins.getAttr system nixpkgs.outputs.legacyPackages;
      modules = [
        {
          home = {
            inherit username;
            stateVersion = "22.11";
            homeDirectory = "/home/${username}";
          };
        }
      ];
    };
in
{
  pluginWithConfigModule = hmModuleEval.options.programs.neovim.plugins.type;
}
