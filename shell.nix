{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "soxin";
  nativeBuildInputs = with pkgs; [
    git
    nixFlakes
  ];

  shellHook = ''
    PATH=${
      pkgs.writeShellScriptBin "nix" ''
        ${pkgs.nixFlakes}/bin/nix --option experimental-features "nix-command flakes ca-references" "$@"
      ''
    }/bin:$PATH
  '';
}
