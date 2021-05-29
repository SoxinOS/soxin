{
  description = "soxin: opiniated configs for everyone";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    nixpkgs.url = github:NixOS/nixpkgs/release-21.05;
    sops-nix.url = "github:Mic92/sops-nix";
    unstable.url = github:NixOS/nixpkgs/nixos-unstable;
    utils.url = path:../../gytis-ivaskevicius/flake-utils-plus;

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... } @ inputs:
    {
      lib = import ./lib inputs;

      nixosModules = (import ./modules) // { soxin = import ./modules/soxin.nix; };
      nixosModule = self.nixosModules.soxin;

      defaultTemplate = {
        path = ./template;
        description = "Template for a personal soxincfg repository.";
      };
    };
}
