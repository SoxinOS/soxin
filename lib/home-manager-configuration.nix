{
  self,
  nixpkgs,
  home-manager,
  ...
}:

{
  # inputs of your own soxincfg
  inputs,

  # Home-manager specific modules.
  modules ? [ ],

  # Home-manager specific extra arguments.
  specialArgs ? { },

  # What packages to use?
  pkgs ? inputs.nixpkgs.legacyPackages.stdenv.hostPlatform."${system}",

  # Define the overlays to apply to pkgs
  overlays ? [ ],

  # What system to build for?
  system,

  ...
}@args:

let
  inherit (builtins) removeAttrs;
  inherit (lib) singleton recursiveUpdate;
  inherit (nixpkgs) lib;

  soxin = self;
  soxincfg = inputs.self;

  otherArguments = removeAttrs args [
    "inputs"
    "modules"
    "overlays"
    "pkgs"
    "specialArgs"
    "system"
  ];

  hmArgs = (
    recursiveUpdate {
      pkgs = import pkgs.path {
        inherit (pkgs) config system;

        overlays = pkgs.overlays ++ overlays;
      };

      extraSpecialArgs = {
        inherit inputs soxin soxincfg;

        mode = "home-manager";
      }
      # include the home-manager special arguments.
      // specialArgs;

      modules =
        modules
        # include Soxin module
        ++ (singleton soxin.nixosModules.soxin)
        # include SoxinCFG module
        ++ (singleton soxincfg.nixosModules.soxincfg);
    } otherArguments
  );
in
home-manager.lib.homeManagerConfiguration hmArgs
