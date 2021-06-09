{ config, mode, pkgs, lib, soxin, ... }:

with lib;

# TODO: submit this module upstream to home-manager
let
  cfg = config.soxin.programs.less;

  keyboardLayout = cfg.keyboardLayout.console.keyMap;

  colemakKeybindings = ''
    #command
    n left-scroll
    e forw-line
    i back-line
    o right-scroll
    k repeat-search
    K reverse-search
  '';

  bepoKeybindings = ''
    #command
    t left-scroll
    s forw-line
    r back-line
    n right-scroll
    ' repeat-search
    ? reverse-search
  '';

in
{
  options.soxin.programs.less = soxin.lib.mkSoxinModule {
    inherit config;
    name = "less";
    includeKeyboardLayout = true;
    extraOptions = {
      quitIfOneScreen = mkOption {
        type = types.bool;
        default = true;
        description = "Causes less to automatically exit if the entire file can be displayed on the first screen.";
      };

      colors = mkOption {
        type = types.bool;
        default = true;
        description = "Enable colored output by allowing only ANSI color escape sequences to be written raw.";
      };

      ignoreCase = mkOption {
        type = types.bool;
        default = true;
        description = "Search case-insensitive";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "home-manager") {
      home.file.".less".source =
        let
          less-key = pkgs.writeText "less-key" (
            ''
              #env
              LESS= ${optionalString cfg.colors ''--RAW-CONTROL-CHARS''} ${optionalString cfg.quitIfOneScreen ''--no-init --quit-if-one-screen''} ${optionalString cfg.ignoreCase ''--ignore-case''}
            ''
            + optionalString (keyboardLayout == "colemak") colemakKeybindings
            + optionalString (keyboardLayout == "fr-bepo") bepoKeybindings
          );
        in
        pkgs.runCommand "less-config" { preferLocalBuild = true; } ''
          ${pkgs.less}/bin/lesskey -o $out ${less-key}
        '';
    })
  ]);
}
