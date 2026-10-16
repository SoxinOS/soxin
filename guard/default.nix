# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  git,
}:

stdenvNoCC.mkDerivation {
  pname = "soxin-guard";
  version = "2.0.0";

  src = ./soxin-guard.py;
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/libexec/soxin-guard.py
    makeWrapper ${python3.interpreter} $out/bin/soxin-guard \
      --add-flags $out/libexec/soxin-guard.py \
      --prefix PATH : ${lib.makeBinPath [ git ]}
    runHook postInstall
  '';

  meta = {
    description = "Fail when a repository carries private material";
    license = lib.licenses.mit;
    mainProgram = "soxin-guard";
  };
}
