inputs@{ self, deploy-rs, ... }:

{
  example = {
    # System architecture.
    system = "x86_64-linux";
    # <name> of the channel to be used. Defaults to `nixpkgs`
    channelName = "unstable";
    # Extra arguments to be passed to the modules.
    extraArgs = {
      abc = 123;
    };
    # Host specific configuration.
    modules = [ ./example/configuration.nix ];

    deploy = {
      hostname = "host.example.com";
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.example;
      };
    };
  };
}
