{ inputs }:

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
  };
}
