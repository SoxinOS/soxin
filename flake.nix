
{
  description = "Soxin a NixOS-based opinionated cross-platform system";

  edition = 201909;

  inputs = {
    home-manager = {
      type = "github";
      owner = "rycee";
      repo = "home-manager";

      # branch is bqv-flakes
      rev = "e13bd1e79372c58cc1e86e45bdf304f4b6770fe3";
    };
  };

  outputs = { self, nixpkgs }: {

  };
}
