{
  description = "Soxin ...";

  inputs = {
    nixpkgs-master.url = "nixpkgs/master";
    nixpkgs-release.url = "nixpkgs/release-20.03";
    home-manager.url = "github:rycee/home-manager/bqv-flakes";
  };

  outputs = inputs@{ self, nixpkgs-master, nixpkgs-release, home-manager }: {
    nixosConfigurations.default = import ./sample-host.nix;
  };
}
