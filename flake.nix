{
  description = "soxin: opiniated configs for everyone";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    futils.url = "github:numtide/flake-utils";
    nmd = {
      url = "gitlab:rycee/nmd";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, futils, nmd } @ inputs:
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

          packages = (self.lib.overlaysToPkgs self.overlays pkgs) //
            (import ./doc { inherit self nixpkgs pkgs lib; nmdSrc = nmd; });
        }
      );

      outputs = {
        lib = {
          nixosSystem = import ./lib/nixos-system.nix {
            inherit self lib home-manager;
          };
          overlaysToPkgs = import ./lib/overlays-to-pkgs.nix { inherit lib; };
        };

        overlay = self.overlays.packages;

        overlays = import ./overlays // {
          packages = import ./pkgs;
        };

        nixosModules = (import ./modules) // {
          soxin = import ./modules/soxin.nix;
        };

        defaultTemplate = {
          path = ./template;
          description = "Template for a personal soxincfg repository.";
        };
      };
    in
    recursiveUpdate multiSystemOutputs outputs;
}
