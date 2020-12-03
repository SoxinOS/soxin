{
  description = "Soxin template flake";

  inputs = {
    nixos.url = "nixpkgs/nixos-20.09";
    master.url = "nixpkgs/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixos";
    };
    soxin = {
      url = "github:SoxinOS/soxin";
      inputs = {
        nixpkgs.follows = "nixos";
        home-manager.follows = "home-manager";
      };
    };
    futils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixos, master, home-manager, soxin, futils } @ inputs:
    let
      inherit (nixos) lib;
      inherit (nixos.lib) recursiveUpdate;
      inherit (futils.lib) eachDefaultSystem;

      pkgImport = pkgs: system:
        import pkgs {
          inherit system;
          overlays = lib.attrValues self.overlays;
          config = { allowUnfree = true; };
        };

      pkgset = system: {
        nixos = pkgImport nixos system;
        master = pkgImport master system;
      };

      multiSystemOutputs = eachDefaultSystem (system:
        let
          pkgset' = pkgset system;
          osPkgs = pkgset'.nixos;
          pkgs = pkgset'.master;
        in
        {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              git
              nixpkgs-fmt
              pre-commit
            ];
          };

          packages = soxin.lib.overlaysToPkgs self.overlays pkgs;
        }
      );

      outputs = {
        overlay = self.overlays.packages;

        overlays = import ./overlays;

        nixosModules = recursiveUpdate (import ./modules) {
          profiles = import ./profiles;
        };

        nixosConfigurations =
          let
            system = "x86_64-linux";
            pkgset' = pkgset system;
          in
          import ./hosts (
            recursiveUpdate inputs {
              inherit lib system;
              pkgset = pkgset';
            }
          );
      };
    in
    recursiveUpdate multiSystemOutputs outputs;
}
