{ pkgs, lib, ... }:

{
  nix = {
    package = pkgs.nixFlakes;

    useSandbox = true;

    extraOptions = ''
      experimental-features = nix-command flakes ca-references
    '';
  };
}
