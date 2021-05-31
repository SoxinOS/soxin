inputs@{ self, deploy-rs, nixpkgs, ... }:

{
  minimal =
    let
      system = "x86_64-linux";
    in
    {
      # System architecture.
      inherit system;
      # <name> of the channel to be used. Defaults to `nixpkgs`
      channelName = "nixpkgs";
      # Extra arguments to be passed to the modules.
      extraArgs = { };
      # Host specific configuration.
      modules = [ ./minimal/configuration.nix ];

      deploy = {
        hostname = "host.minimal.com";
        profiles.system = {
          sshUser = "root";
          user = "root";
          path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.minimal;
        };
      };
    };
}
