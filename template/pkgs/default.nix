# Custom packages
final: prev: {
  helloSh = final.callPackage ./hello-sh { };
}
