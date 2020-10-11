{
  description = "soxin: opiniated configs for everyone";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    futils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, futils } @ inputs:
    let
      inherit (nixpkgs) lib;
      inherit (lib) recursiveUpdate;
      inherit (futils.lib) eachDefaultSystem;

      pkgImport = pkgs: system:
        import pkgs {
          inherit system;
        };

      multiSystemOutputs = eachDefaultSystem (system:
        let
          pkgs = pkgImport nixpkgs system;
        in
        {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              git
              nixpkgs-fmt
              pre-commit
            ];
          };
        }
      );

      outputs = {
        lib = lib.extend (final: prev: {
          nixosSystem = import ./lib/nixos-system.nix {
            lib = prev;
            inherit self home-manager;
          };
        });

        nixosModules = {
          soxin = import ./modules/list.nix;
        };

        defaultTemplate = {
          path = ./template;
          description = "Template for a personal soxincfg repository.";
        };
      };
    in
    recursiveUpdate multiSystemOutputs outputs;
}
