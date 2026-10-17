# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  nix-diff,
}:

stdenvNoCC.mkDerivation {
  pname = "soxin-parity";
  version = "2.0.0";

  src = ./soxin-parity.py;
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  # nix itself comes from the caller's PATH, so the comparison runs with the
  # caller's store and settings.
  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/libexec/soxin-parity.py
    makeWrapper ${python3.interpreter} $out/bin/soxin-parity \
      --add-flags $out/libexec/soxin-parity.py \
      --prefix PATH : ${lib.makeBinPath [ nix-diff ]}
    runHook postInstall
  '';

  meta = {
    description = "Compare the derivations of hosts built two ways with nix-diff";
    license = lib.licenses.mit;
    mainProgram = "soxin-parity";
  };
}
