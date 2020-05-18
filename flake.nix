
{
  description = "Soxin a NixOS-based opinionated cross-platform system";

  edition = 201909;

  inputs = {
    home-manager = {
      type = "github";
      owner = "rycee";
      repo = "home-manager";
    };
  };

  outputs = { self, nixpkgs }: {

  };
}
