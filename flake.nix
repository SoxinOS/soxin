{
  description = "Soxin ...";

  inputs = {
    nixpkgs-master.url = "nixpkgs/master";
    nixpkgs-release.url = "nixpkgs/release-20.03";
    # home-manager.url = "github:rycee/home-manager/bqv-flakes";
    home-manager.url = "git+file:///yl/code/stories/opensource/home-manager/flakes/github.com/rycee/home-manager";
  };

  outputs = inputs@{ self, nixpkgs-master, nixpkgs-release, home-manager }: {
    nixosConfigurations = {
      niximg = nixpkgs-release.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ modulesPath, ... }: {
        imports = [
          "${modulesPath}/installer/cd-dvd/iso-image.nix"
          ];

          isoImage.makeEfiBootable = true;
          isoImage.makeUsbBootable = true;
          networking.networkmanager.enable = true;
        })
        ];
      };
    };
  };
}
