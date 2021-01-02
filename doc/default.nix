{ self, nixpkgs, pkgs, lib, nmdSrc }:
let
  # Dirty hack so the configuration actually evaluates
  soxinExtendedLib = lib.extend (final: prev: {
    evalModules = { modules, ... } @ args: prev.evalModules (args // {
      modules = modules ++ (import "${nixpkgs}/nixos/modules/module-list.nix") ++ [{
        nixpkgs.system = "x86_64-linux";
      }];
      specialArgs = {
        mode = "documentation";
        soxin = self;
      };
    });
  });

  nmd = import nmdSrc { inherit pkgs; lib = soxinExtendedLib; };
  soxinModulesDocs = nmd.buildModulesDocs {
    modules = builtins.attrValues self.nixosModules;
    moduleRootPaths = [ self ];
    mkModuleUrl = path: "https://github.com/SoxinOS/Soxin/blob/master/${path}#blob-path";
    channelName = "soxin";
    docBook.id = "soxin-options";
  };

  docs = nmd.buildDocBookDocs {
    pathName = "soxin";
    modulesDocs = [ soxinModulesDocs ];
    documentsDirectory = ./.;
    chunkToc = ''
      <toc>
        <d:tocentry xmlns:d="http://docbook.org/ns/docbook" linkend="book-soxin-manual"><?dbhtml filename="index.html"?>
          <d:tocentry linkend="ch-options"><?dbhtml filename="options.html"?></d:tocentry>
          <!--<d:tocentry linkend="ch-tools"><?dbhtml filename="tools.html"?></d:tocentry>
          <d:tocentry linkend="ch-release-notes"><?dbhtml filename="release-notes.html"?></d:tocentry>-->
        </d:tocentry>
      </toc>
    '';
  };
in
{
  soxinManual = docs.html;
}
