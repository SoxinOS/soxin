{
  description = "soxin: opiniated configs for everyone";

  inputs = {
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus/v1.3.1";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs";
    nur.url = "github:nix-community/NUR";
    sops-nix.url = "github:Mic92/sops-nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { flake-utils-plus, nixpkgs, self, ... } @ inputs:
    let
      inherit (nixpkgs) lib;
      inherit (lib) recurseIntoAttrs recursiveUpdate;
      inherit (flake-utils-plus.lib) eachDefaultSystem flattenTree;

      anySystemOutputs = {
        defaultTemplate = {
          path = ./template;
          description = "Template for a personal soxincfg repository.";
        };

        lib = import ./lib inputs;

        nixosModules = (import ./modules) // { soxin = import ./modules/soxin.nix; };
        nixosModule = self.nixosModules.soxin;

        overlay = final: prev: { soxin = import ./pkgs prev; };
      };

      specificSystemOutputs = eachDefaultSystem (system:
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

          packages = flattenTree (import ./pkgs pkgs);
        }
      );
    in
    recursiveUpdate anySystemOutputs specificSystemOutputs;
}
