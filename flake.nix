{
  description = "soxin: opiniated configs for everyone";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus/1.5.0";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs";
    nur.url = "github:nix-community/NUR";

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
  };

  outputs =
    {
      flake-utils-plus,
      nixpkgs,
      self,
      ...
    }@inputs:
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

        nixosModules = (import ./modules) // {
          soxin = import ./modules/soxin.nix;
        };
        nixosModule = self.nixosModules.soxin;

        overlay = final: prev: { soxin = import ./pkgs prev; };
      };

      specificSystemOutputs = eachDefaultSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              git
              nixfmt-rfc-style
            ];
          };

          packages = flattenTree (import ./pkgs pkgs);

          formatter = pkgs.nixfmt-rfc-style;
        }
      );
    in
    recursiveUpdate anySystemOutputs specificSystemOutputs;
}
