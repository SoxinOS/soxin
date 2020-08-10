{
  description = "Soxin ...";

  inputs = {
    nixpkgs.url = "nixpkgs/master";
    # home-manager.url = "github:rycee/home-manager/bqv-flakes";
    home-manager.url = "git+file:///yl/code/stories/opensource/home-manager/flakes/github.com/rycee/home-manager";
  };

  outputs = inputs@{ self, nixpkgs, home-manager }: {
    nixosModules = import ./modules/list.nix;
  };
}
