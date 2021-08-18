#!/usr/bin/env bash

set -euo pipefail

readonly action="${1:-}"
readonly host="${2:-$(hostname)}"

isDarwin() {
	local os="$(uname -s)"
	[[ "${os}" == "Darwin" ]]
}

isLinux() {
	local os="$(uname -s)"
	[[ "${os}" == "Linux" ]]
}

isNixOS() {
	has nixos-version
}

# Usage: has <command>
#
# Returns 0 if the <command> is available. Returns 1 otherwise. It can be a
# binary in the PATH or a shell function.
#
# Example:
#
#    if has curl; then
#      echo "Yes we do"
#    fi
#
has() {
	type "$1" &>/dev/null
}

isSupported() {
    isNixOS && return 0
    isDarwin && return 0

    if [[ -f /etc/os-release ]]; then
        local os="$(awk -F= '/^ID=/ {print $2}' /etc/os-release | tr -d '\n')"
        case "$os" in
            nixos|debian)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi

    return 1
}

if ! isSupported; then
    echo "Sorry, your operating system is not supported"
    exit 1
fi

function usage() {
    >&2 echo "USAGE: $0 <action> [hostname]"
}

if [[ -z "${action:-}" ]]; then
    usage
    exit 1
fi

case "${action}" in
    build)
        if isNixOS; then
            nix build ".#nixosConfigurations.${host}.config.system.build.toplevel" --show-trace
        elif isDarwin; then
            nix build ".#darwinConfigurations.${host}.system" --show-trace
        else
            home-manager build --flake ".#${host}" --show-trace
        fi
        ;;
    test)
        if isNixOS; then
            sudo nixos-rebuild --flake ".#${host}" test --show-trace
        elif isDarwin; then
            >&2 echo test is not support on nix-darwin
            exit 1
        else
            >&2 echo test is not support on home-manager
            exit 1
        fi
        ;;
    switch)
        if isNixOS; then
            sudo nixos-rebuild --flake ".#${host}" test --show-trace
        elif isDarwin; then
            "$0" build "$host"
            sudo ./result/activate
            ./result/activate-user
        else
            home-manager switch --flake ".#${host}"
        fi
        ;;
    boot)
        if isNixOS; then
            sudo nixos-rebuild --flake ".#${host}" boot --show-trace
        elif isDarwin; then
            >&2 echo boot is not support on nix-darwin
            exit 1
        else
            >&2 echo boot is not support on home-manager
            exit 1
        fi
        ;;
    *)
        usage
        exit 1
        ;;
esac
