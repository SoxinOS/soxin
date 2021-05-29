channels@{ ... }:

let
  inherit (channels.nixpkgs) callPackage;
in
{
  helloSh = callPackage ./hello-sh { };
}
