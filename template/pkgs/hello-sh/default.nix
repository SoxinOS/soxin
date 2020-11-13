{ stdenv }:

stdenv.mkDerivation {
  pname = "helloSh";
  version = "1.0.0";

  src = ./.;

  installPhase = ''
    install -Dm755 $src/hello.sh $out/bin/hello.sh
  '';

  meta = with stdenv.lib; {
    platforms = platforms.unix;
  };
}
