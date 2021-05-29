{
  description = "soxin: opiniated configs for everyone";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/release-21.05;
    unstable.url = github:nixos/nixpkgs/nixos-unstable;
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils.url = path:../../gytis-ivaskevicius/flake-utils-plus;
  };

  outputs = { ... } @ inputs:
    {
      lib = import ./lib inputs;
    };
}
