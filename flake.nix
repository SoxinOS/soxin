
{
  description = "Soxin a NixOS-based opinionated cross-platform system";

  edition = 201909;

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    home-manager.url = "github:rycee/home-manager/bqv-flakes";
  };

  outputs = { self, nixpkgs, home-manager }: {

  };
}
