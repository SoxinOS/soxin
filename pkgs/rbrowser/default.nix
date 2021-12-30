{ brave
, chromium
, firefox
, lib
, makeDesktopItem
, rofi
, runtimeShell
, stdenvNoCC
, vivaldi
, writeScriptBin

, browsers ? [
    { name = "brave"; profile = "default"; flags = [ ]; }
    { name = "chromium"; profile = "default"; flags = [ ]; }
    { name = "firefox"; profile = "default"; flags = [ ]; }
    { name = "vivaldi"; profile = "default"; flags = [ ]; }
  ]
}:
let
  # What are the supported browsers by Rbrowser?
  supportedBrowsers = [ "brave" "chromium" "firefox" "vivaldi" ];

  inherit (lib) foldl intersectLists optional optionalString;

  # compute what browser we need
  withBrowser =
    let
      matchBrowsers = browsers: browser: builtins.filter (b: b.name == browser) browsers;
    in
    browser:
    let mb = builtins.length (matchBrowsers browsers browser); in mb >= 1;
  withBrave = withBrowser "brave";
  withChromium = withBrowser "chromium";
  withFirefox = withBrowser "firefox";
  withVivaldi = withBrowser "vivaldi";

  rbrowser = writeScriptBin "rbrowser"
    (
      let
        items = builtins.concatStringsSep "\n" (map (browser: ''"${browser.name}@${browser.profile}"'') browsers);

        declareFlags = builtins.concatStringsSep "\n" (map
          (b: ''
            if [[ "$browser" == "${b.name}" ]] && [[ "$profile" == "${b.profile}" ]]; then
              args=(''${args[@]} ${builtins.concatStringsSep " " (map (f: ''"${f}"'') b.flags)})
            fi
          '')
          (builtins.filter (b: b.flags != [ ]) browsers));
      in
      ''
        #! ${runtimeShell}
        #
        #  Copyright (c) 2010-2020 Wael Nasreddine <wael.nasreddine@gmail.com>
        #
        #  This program is free software; you can redistribute it and/or modify
        #  it under the terms of the GNU General Public License as published by
        #  the Free Software Foundation; either version 2 of the License, or
        #  (at your option) any later version.
        #
        #  This program is distributed in the hope that it will be useful,
        #  but WITHOUT ANY WARRANTY; without even the implied warranty of
        #  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        #  GNU General Public License for more details.
        #
        #  You should have received a copy of the GNU General Public License
        #  along with this program; if not, write to the Free Software
        #  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
        #  USA.
        #

        set -euo pipefail

        function help()
        {
          echo -e "USAGE: rbrowser [options] <url>"
          echo -e "\t -h, --help                - this message"
          echo -e "\t -p, --autodetect          - detect browser profiles by scanning their profiles directory"
          echo -e "\t -p, --profile             - the profile to use"
          echo -e "\t -b, --browser             - the browser to use. Default: chromium"
        }

        # has_key <needle> <haystack> returns 0 if the haystack has the needle
        # otherwise will return 1
        has_key() {
          local needle="''${1}"
          shift
          local haystack=("''${@}")

          for chk in "''${haystack[@]}"; do
            if [[ "''${chk}" == "''${needle}" ]]; then
              return 0
            fi
          done

          return 1
        }

        ${optionalString withBrave ''brave="${brave}/bin/brave"''}
        ${optionalString withChromium ''chromium="${chromium}/bin/chromium"''}
        ${optionalString withFirefox ''firefox="${firefox}/bin/firefox"''}
        ${optionalString withVivaldi ''vivaldi="${vivaldi}/bin/vivaldi"''}

        log_depth="0"
        args=""
        browser=""
        autodetect=false

        while [[ $# -ge 1 ]]; do
          case "''${1}" in
            -a|--autodetect)
              autodetect=true
              shift
              ;;
            -h|--help)
              help
              exit 0
              ;;
            -p|--profile)
              if [[ -z "''${2:-}" ]]; then
                echo -e "ERR: --profile requires an argument"
                help
                exit 1
              fi
              profile="''${2}"
              shift 2
              ;;
            -b|--browser)
              if [[ -z "''${2:-}" ]]; then
                echo -e "ERR: --browser requires an argument"
                help
                exit 1
              fi
              browser="''${2}"
              shift 2
              ;;
            *)
              args=( ''${@} )
              break
              ;;
          esac
        done

        # the profile paths per browser
        ${optionalString withBrave ''BRAVE_PROFILES_PATH="''${HOME}/.config/brave/profiles"''}
        ${optionalString withChromium ''CHROMIUM_PROFILES_PATH="''${HOME}/.config/chromium/profiles"''}
        ${optionalString withFirefox ''FIREFOX_PROFILES_PATH="''${HOME}/.mozilla/firefox/profiles"''}
        ${optionalString withVivaldi ''VIVALDI_PROFILES_PATH="''${HOME}/.config/vivaldi/profiles"''}

        # make sure we have both profile and a browser.
        if [[ -n "''${profile:-}" ]] && [[ -z "''${browser:-}" ]]; then
          echo -e "ERR: the profile was set to ''${profile}, but the browser is empty. The browser is required with --profile, aborting..."
          exit 1
        fi

        if [[ -z "''${profile:-}" ]]; then
          # contruct the items to show to rofi
          items=(${items})

          if [[ "$autodetect" == "true" ]]; then
          ${optionalString withBrave ''
            if [[ -d "$BRAVE_PROFILES_PATH" ]]; then
              for i in $BRAVE_PROFILES_PATH/*; do
                if [[ -d "''${i}" ]]; then
                  prof="brave@$(basename "''${i}")"
                  if ! has_key "$prof" "''${items[@]}"; then
                    items+=("$prof")
                  fi
                fi
              done
            fi
          ''}
          ${optionalString withChromium ''
            if [[ -d "$CHROMIUM_PROFILES_PATH" ]]; then
              for i in $CHROMIUM_PROFILES_PATH/*; do
                if [[ -d "''${i}" ]]; then
                  prof="chromium@$(basename "''${i}")"
                  if ! has_key "$prof" "''${items[@]}"; then
                    items+=("$prof")
                  fi
                fi
              done
            fi
          ''}
          ${optionalString withFirefox ''
            if [[ -d "$FIREFOX_PROFILES_PATH" ]]; then
              for i in $FIREFOX_PROFILES_PATH/*; do
                if [[ -d "''${i}" ]]; then
                  prof="firefox@$(basename "''${i}")"
                  if ! has_key "$prof" "''${items[@]}"; then
                    items+=("$prof")
                  fi
                fi
              done
            fi
          ''}
          ${optionalString withVivaldi ''
            if [[ -d "$VIVALDI_PROFILES_PATH" ]]; then
              for i in $VIVALDI_PROFILES_PATH/*; do
                if [[ -d "''${i}" ]]; then
                  prof="vivaldi@$(basename "''${i}")"
                  if ! has_key "$prof" "''${items[@]}"; then
                    items+=("$prof")
                  fi
                fi
              done
            fi
          ''}
          fi

          # Some applications such as Slack are failing to open rbrowser
          # because of fails to access the system locale. I'm not sure why this
          # is happening. A workaround is to use LC_ALL=C which essentially
          # disables the locale lookup. Bash (the shebang) is still complaining
          # about locale not found.
          entry="$(LC_ALL=C ${rofi}/bin/rofi -dmenu < <(printf "%s\n" "''${items[@]}"))"
          browser="$(echo "''${entry}" | cut -d@ -f1)"
          profile="$(echo "''${entry}" | cut -d@ -f2)"
        fi

        case "''${browser}" in
        ${optionalString withBrave ''
          "brave")
            PROFILES_PATH="''${BRAVE_PROFILES_PATH}"
            ;;
        ''}
        ${optionalString withChromium ''
          "chromium")
            PROFILES_PATH="''${CHROMIUM_PROFILES_PATH}"
            ;;
        ''}
        ${optionalString withFirefox ''
          "firefox")
            PROFILES_PATH="''${FIREFOX_PROFILES_PATH}"
            ;;
        ''}
        ${optionalString withVivaldi ''
          "vivaldi")
            PROFILES_PATH="''${VIVALDI_PROFILES_PATH}"
            ;;
        ''}
          *)
            echo -e "ERR: the browser ''${browser} is not supported"
            exit 1
            ;;
        esac

        if [[ -z "''${profile}" ]]; then
          echo -e "ERR: no profile was selected, aborting..."
          exit 1
        fi

        if [[ ! -d "''${PROFILES_PATH}/''${profile}" ]]; then
          echo -e "WARN: the selected profile does not exists, creating one"
          mkdir -p "''${PROFILES_PATH}/''${profile}"
        fi

        # declare flags (if any)
        ${declareFlags}

        if [[ -f "''${PROFILES_PATH}/''${profile}/.cmdline_args" ]]; then
          args=(''${args[@]} $(cat "''${PROFILES_PATH}/''${profile}/.cmdline_args"))
        fi

        case "''${browser}" in
        ${optionalString withBrave ''
          "brave")
            (exec "''${brave}" --user-data-dir="''${PROFILES_PATH}/''${profile}" "''${args[@]}" &>/dev/null)&
            ;;
        ''}
        ${optionalString withChromium ''
          "chromium")
            (exec "''${chromium}" --user-data-dir="''${PROFILES_PATH}/''${profile}" "''${args[@]}" &>/dev/null)&
            ;;
        ''}
        ${optionalString withFirefox ''
          "firefox")
            (exec "''${firefox}" --profile "''${PROFILES_PATH}/''${profile}" --new-tab "''${args[@]}" &>/dev/null)&
            ;;
        ''}
        ${optionalString withVivaldi ''
          "vivaldi")
            (exec "''${vivaldi}" --user-data-dir="''${PROFILES_PATH}/''${profile}" "''${args[@]}" &>/dev/null)&
            ;;
        ''}
          *)
            echo -e "ERR: the browser ''${browser} is not supported"
            exit 1
            ;;
        esac
      ''
    );

  desktopItem = makeDesktopItem {
    categories = "GTK;Network;WebBrowser;";
    desktopName = "Relay Browser";
    exec = "rbrowser %U";
    genericName = "Web Browser";
    icon = "chromium";
    mimeType = "x-scheme-handler/unknown;x-scheme-handler/about;text/html;text/xml;application/xhtml+xml;text/mml;x-scheme-handler/http;x-scheme-handler/https;";
    name = "rbrowser";
  };
in
assert lib.asserts.assertMsg (withBrave || withChromium || withFirefox || withVivaldi) "At least one browser must be enabled.";
stdenvNoCC.mkDerivation rec {
  name = "rbrowser";

  src = rbrowser;

  installPhase = ''
    install -Dm755 $src/bin/rbrowser $out/bin/rbrowser

    mkdir -p $out/share
    ln -s ${desktopItem}/share/applications $out/share/applications
  '';

  passthru = { inherit supportedBrowsers; };

  meta =
    let
      bravePlatforms = brave.meta.platforms;
      chromiumPlatforms = chromium.meta.platforms;
      firefoxPlatforms = firefox.meta.platforms;
      vivaldiPlatforms = vivaldi.meta.platforms;

      browsersPlatforms = (optional withBrave bravePlatforms)
        ++ (optional withChromium chromiumPlatforms)
        ++ (optional withFirefox firefoxPlatforms)
        ++ (optional withVivaldi vivaldiPlatforms);
      mkPlatforms = foldl (lhs: rhs: intersectLists lhs rhs) lib.platforms.unix;
      platforms = mkPlatforms browsersPlatforms;
    in
    {
      inherit platforms;

      description = "A rofi-based browser picker that supports the following browsers: ${builtins.concatStringsSep " " supportedBrowsers}.";
      maintainers = with lib.maintainers; [ kalbasit ];
    };
}
