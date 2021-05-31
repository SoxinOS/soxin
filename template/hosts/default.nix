inputs@{ self, deploy-rs, nixpkgs, ... }:

(import ./nixoses inputs)
//
(import ./darwins inputs)
  //
(import ./home-managers inputs)
