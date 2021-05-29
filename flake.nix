{
  description = "soxin: opiniated configs for everyone";

  inputs = {
    deploy-rs.url = github:serokell/deploy-rs;
    nixpkgs.url = github:NixOS/nixpkgs/release-21.05;
    nur.url = github:nix-community/NUR;
    sops-nix.url = github:Mic92/sops-nix;
    unstable.url = github:NixOS/nixpkgs/nixos-unstable;
    utils.url = github:gytis-ivaskevicius/flake-utils-plus/v1.1.0;

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... } @ inputs:
    {
      defaultTemplate = {
        path = ./template;
        description = "Template for a personal soxincfg repository.";
      };

      lib = import ./lib inputs;

      nixosModules = (import ./modules) // { soxin = import ./modules/soxin.nix; };
      nixosModule = self.nixosModules.soxin;

      overlay = import ./overlays;
    };
}
