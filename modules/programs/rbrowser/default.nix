{ mode, config, pkgs, lib, ... }:

with lib;
let
  cfg = config.soxin.programs.rbrowser;

  browserSubmodule = { name, ... }: {
    options = {
      enable = mkOption {
        default = true;
        type = types.bool;
        description = ''
          Whether to enable the ${name} integration with rbrowser.
        '';
      };
    };
  };

  mimeTypes = [
    "application/pdf"
    "application/x-extension-htm"
    "application/x-extension-html"
    "application/x-extension-shtml"
    "application/x-extension-xht"
    "application/x-extension-xhtml"
    "application/xhtml+xml"
    "text/html"
    "x-scheme-handler/about"
    "x-scheme-handler/chrome"
    "x-scheme-handler/ftp"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/irc"
    "x-scheme-handler/ircs"
    "x-scheme-handler/mailto"
    "x-scheme-handler/unknown"
    "x-scheme-handler/webcal"
  ];
  rbrowserMimeList = concatStringsSep "\n" (
    map (mimeType: "${mimeType}=rbrowser.desktop") mimeTypes
  );
  mimeList = ''
    [Default Applications]
    ${rbrowserMimeList}
  '';
in
{
  options = {
    soxin.programs.rbrowser = {
      enable = mkEnableOption "rbrowser, a rofi browser picker";

      browsers = {
        brave = mkOption {
          type = types.submodule browserSubmodule;
          default = { };
        };
        chromium = mkOption {
          type = types.submodule browserSubmodule;
          default = { };
        };
        firefox = mkOption {
          type = types.submodule browserSubmodule;
          default = { };
        };
      };

      package = mkOption {
        type = types.package;
        default = pkgs.rbrowser.override {
          withBrave = cfg.browsers.brave.enable;
          withChromium = cfg.browsers.chromium.enable;
          withFirefox = cfg.browsers.firefox.enable;
        };
        defaultText = ''
          pkgs.rbrowser.override {
            withBrave = cfg.browsers.brave.enable;
            withChromium = cfg.browsers.chromium.enable;
            withFirefox = cfg.browsers.firefox.enable;
          };
        '';
        example = literalExample ''
          pkgs.rbrowser.override {
            withBrave = false;
          };
        '';
        description = ''
          The rbrowser package to use. It it automatically overriden
          depending on the browsers you enabled.

          If you choose to use your own, it should expose a binary under
          `bin/rbrowser` that will be used by this module.
        '';
      };

      setMimeList = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether to create $HOME/.local/share/applications/mimeapps.list and
          $HOME/.config/mimeapps.list that set rbrowser as the default
          application for many filetypes usually supported by browsers.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "NixOS") {
      environment.variables.BROWSER = "${cfg.package}/bin/rbrowser";

      environment.systemPackages = [ cfg.package ];
    })

    (optionalAttrs (mode == "home-manager") {
      home.sessionVariables.BROWSER = "${cfg.package}/bin/rbrowser";

      home.packages = [ cfg.package ];

      home.file = mkIf (cfg.setMimeList) {
        ".local/share/applications/mimeapps.list".text = mimeList;
        ".config/mimeapps.list".text = mimeList;
      };
    })
  ]);
}
