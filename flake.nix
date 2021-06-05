{
  description = "soxin: opiniated configs for everyone";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    futils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, darwin, home-manager, futils } @ inputs:
    let
      inherit (nixpkgs) lib;
      inherit (lib) recursiveUpdate;
      inherit (futils.lib) eachDefaultSystem;

      multiSystemOutputs = eachDefaultSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              git
              nixpkgs-fmt
              pre-commit
            ];
          };

          packages = self.lib.overlaysToPkgs self.overlays pkgs;
        }
      );

      outputs = {
        lib = import ./lib (recursiveUpdate inputs { inherit lib; });

        overlay = self.overlays.packages;

        overlays = import ./overlays;

        nixosModules = (import ./modules) // { soxin = import ./modules/soxin.nix; };
        nixosModule = self.nixosModules.soxin;
        /* For now they are the same. */
        darwinModules = self.nixosModules;
        darwinModule = self.darwinModules.soxin;

        defaultTemplate = {
          path = ./template;
          description = "Template for a personal soxincfg repository.";
        };
      };
    in
    recursiveUpdate multiSystemOutputs outputs;
}
