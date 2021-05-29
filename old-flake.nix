{
  outputs = { self, nixpkgs, home-manager, futils } @ inputs:
    let
      inherit (nixpkgs) lib;
      inherit (lib) recursiveUpdate;
      inherit (futils.lib) eachDefaultSystem;

      multiSystemOutputs = eachDefaultSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              git
              nixpkgs-fmt
              pre-commit
            ];
          };

          packages = self.lib.overlaysToPkgs self.overlays pkgs;
        }
      );

      outputs = {
        lib = import ./lib (recursiveUpdate inputs { inherit lib; });

        overlay = self.overlays.packages;

        overlays = import ./overlays;

        nixosModules = (import ./modules) // { soxin = import ./modules/soxin.nix; };
        nixosModule = self.nixosModules.soxin;

        defaultTemplate = {
          path = ./template;
          description = "Template for a personal soxincfg repository.";
        };
      };
    in
    recursiveUpdate multiSystemOutputs outputs;
}