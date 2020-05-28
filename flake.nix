
{
  description = "Soxin a NixOS-based opinionated cross-platform system";

  edition = 201909;

  inputs = {
    nixpkgs-unstable = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";

      # branch is master
      rev = "2738ca86bd623934d816bef90f1867002c119950";
    };

    nixpkgs-20-03 = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";

      # branch is release-20.03
      rev = "e985ffea2d640bb6fe7d5ef7aa968b2b7d107f47";
    };

    home-manager = {
      type = "github";
      owner = "rycee";
      repo = "home-manager";

      # branch is bqv-flakes
      rev = "e13bd1e79372c58cc1e86e45bdf304f4b6770fe3";
    };
  };

  outputs = { self, nixpkgs-unstable, nixpkgs-20-03, home-manager }: {

  };
}
