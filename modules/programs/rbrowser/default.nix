{
  soxin,
  mode,
  config,
  home-manager,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.soxin.programs.rbrowser;

  inherit (pkgs.soxin) rbrowser;

  browserSubmodule =
    let
      getFromDagName =
        dagName: index:
        let
          hasAt = lib.stringAsChars (x: if x == "@" then x else "") dagName == "@";
          nameProfile = builtins.head (builtins.tail (builtins.split "^(.*)@(.*)$" dagName));
        in
        assert lib.asserts.assertMsg hasAt
          ''The dagName must be of the format browser@profile, got "${dagName}"!'';
        assert lib.asserts.assertMsg (
          builtins.length nameProfile == 2
        ) "The dagName must be of the format browser@profile.";
        builtins.elemAt nameProfile index;
    in
    { dagName, ... }:
    {
      options = {
        name = mkOption {
          type = types.enum rbrowser.supportedBrowsers;
          default = getFromDagName dagName 0;
          readOnly = true; # do not allow changes to this value
          internal = true; # do not show this option in the manual
          description = ''
            The name of the browser. These browsers are supported: ${builtins.concatStringsSep " " rbrowser.supportedBrowsers}.
          '';
        };

        profile = mkOption {
          type = types.str;
          default = getFromDagName dagName 1;
          readOnly = true; # do not allow changes to this value
          internal = true; # do not show this option in the manual
          description = ''
            The name of the profile.
          '';
        };

        flags = mkOption {
          type = with types; listOf str;
          default = [ ];
          description = ''
            The flags to apply when calling the browser's command.
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
  rbrowserMimeList = concatStringsSep "\n" (map (mimeType: "${mimeType}=rbrowser.desktop") mimeTypes);
  mimeList = ''
    [Default Applications]
    ${rbrowserMimeList}
  '';
in
{
  options = {
    soxin.programs.rbrowser = {
      enable = mkEnableOption "rbrowser, a rofi browser picker";

      browsers = mkOption {
        type = home-manager.lib.hm.types.dagOf (types.submodule browserSubmodule);
        default = { };
        description = ''
          The browsers to enable in Rbrowser.
        '';

        # when the browsers option is accessed, the dag is then converted to an
        # ordered list of attribute set of all browsers.
        apply =
          with pkgs;
          config:
          let
            sortedCommands = home-manager.lib.hm.dag.topoSort config;
          in
          if
            sortedCommands ? result
          # build the list by getting the data attr out of the list of
          # attrs result.
          then
            map (e: e.data) sortedCommands.result
          else
            abort ("Dependency cycle in hook script: " + builtins.toJSON sortedCommands);
      };

      package = mkOption {
        type = types.package;
        default = rbrowser.override { inherit (cfg) browsers; };
        defaultText = ''
          pkgs.soxin.rbrowser.override { inherit (cfg) browsers; };
        '';
        example = ''
          pkgs.soxin.rbrowser.override { browsers = [ { name = "chromium"; profile = "personal"; flags = []; } ]; };
        '';
        description = ''
          The rbrowser package to use. It it automatically overriden depending
          on the browsers you enabled.

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
