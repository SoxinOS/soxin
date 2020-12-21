{ stdenvNoCC
, writeScriptBin
, makeDesktopItem
, withBrave ? true
, brave
, withChromium ? true
, chromium
, withFirefox ? true
, firefox
, rofi
, runtimeShell
}:

assert withBrave || withChromium || withFirefox;
let
  inherit (stdenvNoCC.lib) foldl intersectLists optional optionalString;


  rbrowser = writeScriptBin "rbrowser" ''
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
      echo -e "\t -p, --profile             - the profile to use"
      echo -e "\t -b, --browser             - the browser to use. Default: chromium"
    }

    ${optionalString withBrave ''brave="${brave}/bin/brave"''}
    ${optionalString withChromium ''chromium="${chromium}/bin/chromium"''}
    ${optionalString withFirefox ''firefox="${firefox}/bin/firefox"''}

    log_depth="0"
    args=""
    browser=""

    while [[ $# -ge 1 ]]; do
      case "''${1}" in
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

    # make sure we have both profile and a browser.
    if [[ -n "''${profile:-}" ]] && [[ -z "''${browser:-}" ]]; then
      echo -e "ERR: the profile was set to ''${profile}, but the browser is empty. The browser is required with --profile, aborting..."
      exit 1
    fi

    if [[ -z "''${profile:-}" ]]; then
      items=""
      sep=""
    ${optionalString withBrave ''
      if [[ -d "$BRAVE_PROFILES_PATH" ]]; then
        for i in $BRAVE_PROFILES_PATH/*; do
          if [[ -d "''${i}" ]]; then
            items="''${items}''${sep}brave@$(basename "''${i}")"
            sep="\n"
          fi
        done
      fi
    ''}
    ${optionalString withChromium ''
      if [[ -d "$CHROMIUM_PROFILES_PATH" ]]; then
        for i in $CHROMIUM_PROFILES_PATH/*; do
          if [[ -d "''${i}" ]]; then
            items="''${items}''${sep}chromium@$(basename "''${i}")"
            sep="\n"
          fi
        done
      fi
    ''}
    ${optionalString withFirefox ''
      if [[ -d "$FIREFOX_PROFILES_PATH" ]]; then
        for i in $FIREFOX_PROFILES_PATH/*; do
          if [[ -d "''${i}" ]]; then
            items="''${items}''${sep}firefox@$(basename "''${i}")"
            sep="\n"
          fi
        done
      fi
    ''}
      if [[ -z "''${items}" ]]; then
        echo -e "No profiles found, please run it with the <-b> and <-p> options to create the first profiles"
        exit 1
      fi
      entry="$(${rofi}/bin/rofi -dmenu < <(echo -e "''${items}"))"
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
      *)
        echo -e "ERR: the browser ''${browser} is not supported"
        exit 1
        ;;
    esac
  '';

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
stdenvNoCC.mkDerivation rec {
  name = "rbrowser";

  src = rbrowser;

  phases = [ "installPhase" "fixupPhase" ];

  installPhase = ''
    install -Dm755 $src/bin/rbrowser $out/bin/rbrowser

    mkdir -p $out/share
    ln -s ${desktopItem}/share/applications $out/share/applications
  '';

  meta =
    let
      bravePlatforms = brave.meta.platforms;
      chromiumPlatforms = chromium.meta.platforms;
      firefoxPlatforms = firefox.meta.platforms;
      browsersPlatforms = (optional withBrave bravePlatforms)
        ++ (optional withChromium chromiumPlatforms)
        ++ (optional withFirefox firefoxPlatforms);
      mkPlatforms = foldl (lhs: rhs: intersectLists lhs rhs) stdenvNoCC.lib.platforms.unix;
      platforms = mkPlatforms browsersPlatforms;
    in
    {
      description = "A rofi-based browser picker";
      inherit platforms;
      maintainers = with stdenvNoCC.lib.maintainers; [ kalbasit ];
    };
}
