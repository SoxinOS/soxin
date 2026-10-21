<!--
SPDX-FileCopyrightText: 2026 Wael Nasreddine
SPDX-License-Identifier: MIT
-->

# Soxin

Soxin is a public Nix framework for running a fleet of machines: NixOS
systems, nix-darwin systems and standalone home-manager configurations,
declared as a directory of machines, homes and profiles. Machines are
deployed with Clan's CLI (`clan machines update`).

It is a thin layer on [Clan](https://clan.lol)'s
[flake-parts](https://flake.parts) module. Clan discovers the NixOS and
nix-darwin machines in `machines/<name>/` and builds them. Soxin adds what
Clan lacks: nixpkgs channels whose overlays see every channel, standalone
home-manager hosts, profiles and the fleet's own modules split by kind, a
small module library, sops-nix as an opt-in, pinning of the Nix registry and
NIX_PATH to the fleet's inputs, and module outputs. A thin `lib.mkFleet` wrapper serves flakes that do not use flake-parts
themselves.

This is Soxin v2. v1 (the `flake-utils-plus` based `mkFlake` and the Soxin
modules) lives on the `main` branch.

## The one rule

**Dependencies point one way: private -> public.**

Your fleet (hosts, profiles, private modules, secrets) lives in your own
private flake that consumes Soxin. Soxin never references a consumer: no
hosts, users, inputs, names or secrets of any fleet go into this repository.
A guard enforces it (see [The guard](#the-guard)).

## The fleet layout

```
my-fleet/
├── flake.nix
├── machines/                   # Clan's machines: NixOS and nix-darwin
│   ├── example-server/
│   │   ├── host.nix            # kind, system, channel, profiles, modules
│   │   └── configuration.nix   # imported by Clan
│   └── example-laptop/
│       ├── host.nix
│       └── configuration.nix
├── homes/                      # standalone home-manager hosts
│   └── example-devbox/
│       ├── host.nix
│       └── home.nix
├── profiles/
│   ├── base/                   # bundles of settings, taken by name
│   │   ├── nixos.nix
│   │   ├── darwin.nix
│   │   └── home.nix
│   └── workstation/
│       └── home.nix
└── modules/                    # the fleet's own modules
    ├── nixos.nix
    ├── darwin.nix
    └── home.nix
```

- **`machines/<name>/host.nix`** and **`homes/<name>/host.nix`** declare one
  host each. A host file is a module (an attribute set, or a function of
  `{ inputs, name, ... }`):

  ```nix
  {
    kind = "nixos";            # "nixos" or "darwin" under machines/ (default "nixos"),
                               # "home-manager" under homes/ (the default there)
    system = "x86_64-linux";
    channel = "nixpkgs";       # optional, defaults to fleet.defaultChannel
    profiles = [ "server" ];   # on top of fleet.defaultProfiles
    modules = [ ];             # more modules; Clan imports configuration.nix itself
    specialArgs = { };         # optional, extra module arguments
  }
  ```

  `nixos` and `darwin` hosts are Clan machines (their `kind` is Clan's
  `machineClass`) and become `nixosConfigurations.<name>` and
  `darwinConfigurations.<name>`; Clan imports their `configuration.nix` (and,
  for NixOS, `hardware-configuration.nix` and `disko.nix`) by itself.
  `home-manager` hosts become `homeConfigurations.<name>`. Hosts can also be
  declared inline in `fleet.hosts`.

- **`profiles/<name>/`** holds a `nixos.nix`, `darwin.nix` and/or `home.nix`
  (or `nixos/`, `darwin/`, `home/` directories). A host that takes the profile
  gets the file for its kind; `home.nix` also reaches home-manager inside
  NixOS and nix-darwin hosts.

- **`modules/`** holds the fleet's own `nixos.nix`, `darwin.nix` and
  `home.nix`, imported by every host of that kind.

Every module receives these arguments besides the usual ones: `inputs` (the
fleet flake's inputs), `soxin`, `hostName`, `channels` (every channel's
packages for the host's system), plus whatever `fleet.specialArgs` and the
host add. `inputs`, `soxin` and `fleet.specialArgs` can be used in `imports`.
There is no `mode`: a module that differs by kind is one file per kind
(`nixos.nix`, `darwin.nix`, `home.nix`), and each kind imports its own.
In NixOS and nix-darwin machines, `hostName`, `channels` and a host's own
`specialArgs` are ordinary module arguments, which cannot: Clan passes the
same special arguments to every machine.

Each machine's packages are its channel's (`nixpkgs.pkgs`), while its NixOS
or nix-darwin modules come from the default channel's nixpkgs and from
`fleet.inputs.nix-darwin`, which Clan builds every machine with.

A machine is deployed with `clan machines update <name>`, to the address in
its `clan.core.networking.targetHost`. Clan does not deploy standalone homes;
home-manager switches them itself.

The framework also adds a `host-<name>` check per host that evaluates it.
Clan's own options (`clan.meta`, `clan.inventory`, services, vars) are all
available under `clan`.

### The module library

Soxin ships a small, supported module library. Every host gets it, and its
modules configure nothing until enabled or set:

| Option | |
| --- | --- |
| `soxin.settings.users` | Users declared once (`users.<name>` with `isAdmin`, `isNixTrustedUser`, `sshKeys`), created on NixOS and nix-darwin; other modules add to `groups`. |
| `soxin.settings.keyboard` | Keyboard layouts for the consoles, the X server and home-manager, which programs read. |
| `soxin.settings.theme` | One theme by name from `soxin.themes` (gruvbox-dark and gruvbox-light included), which programs read. |
| `soxin.hardware.yubikey` | YubiKey tools, pcscd and GnuPG's agent with SSH support. |
| `soxin.hardware.serial_console` | The kernel console and GRUB on the first serial port. |

Each module has an `options.nix` and a `nixos.nix`, `darwin.nix` and
`home.nix` that import it, so configuration shared by every kind can set the
options. Outside a Soxin fleet they are `nixosModules`, `darwinModules` and
`homeModules` of this flake: `soxin` for all of them, or one by
`<area>-<name>` (e.g. `nixosModules.settings-users`); `lib.library` gives the
same as plain paths. A fleet that places the library's modules itself sets
`fleet.library.enable = false`.

### Pieces

`flakeModules.default` imports all of Soxin. Each piece is a flake-parts
module of its own, importable alone or with others:

| Module | |
| --- | --- |
| `flakeModules.channels` | `fleet.channels` and perSystem `pkgs`. |
| `flakeModules.profiles` | Profiles and the fleet's modules by kind, `fleet.exportModules`. |
| `flakeModules.hosts` | `fleet.hosts`, the frameworks, sops-nix and the module arguments. |
| `flakeModules.homes` | Standalone home-manager hosts. |
| `flakeModules.machines` | Machines on Clan, with Clan's flake module and `fleet.pinInputs`. |
| `flakeModules.checks` | The `host-<name>` checks. |
| `flakeModules.library` | Soxin's module library on every host. |

`flakeModules.formatter`, not in `default`, formats the repository rather than
the fleet: deadnix, statix and nixfmt through treefmt-nix, as `formatter` (`nix
fmt`), as the `treefmt` hook of git-hooks.nix and as the `treefmt` and
`pre-commit` checks, all over the importing flake's own files. The hook runs
treefmt's wrapper, so a commit the hook accepts is one `nix fmt` leaves alone.
Add formatters with `perSystem.treefmt.programs`, hooks with
`perSystem.pre-commit.settings.hooks`, and install the hook from a development
shell with `inputsFrom = [ config.pre-commit.devShell ]`.

## A minimal fleet flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    soxin = {
      url = "github:SoxinOS/soxin/v2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.soxin.lib.mkFleet {
      inherit inputs;
      root = ./.;

      channels = {
        nixpkgs-unstable.input = inputs.nixpkgs-unstable;
        # Take some packages from unstable.
        nixpkgs.overlays = channels: [
          (final: prev: { inherit (channels.nixpkgs-unstable) hello; })
        ];
      };

      defaultProfiles = [ "base" ];
      sops.enable = true;

      # Extra module arguments, e.g. from a nixos-hardware input:
      # specialArgs.nixos = { inherit (inputs) nixos-hardware; };
    };
}
```

A flake-parts flake imports `inputs.soxin.flakeModules.default` and sets the
same options under `fleet`. That module imports Clan's flake-parts module
itself, so a fleet does not import Clan's as well. Clan follows Soxin's
nixpkgs, which a fleet points at its own pin with `follows`.

`nix flake init -t github:SoxinOS/soxin/v2` copies the [example
fleet](examples/fleet): one NixOS, one nix-darwin and one standalone
home-manager host, all made up.

### Options

| Option | Default | |
| --- | --- | --- |
| `root` | `null` | The fleet directory and Clan's directory; machines are in its `machines/`, and `homesDir`, `profilesDir` and `modulesDir` default to its subdirectories. |
| `hosts.<name>` | from `machines/` and `homes/` | Hosts; see `host.nix` above. |
| `homesDir`, `profilesDir`, `modulesDir` | under `root` | Where standalone homes, profiles and the fleet's modules are found. |
| `profiles.<name>.{nixos,darwin,home}` | from `profiles/` | Profiles as lists of modules. |
| `defaultProfiles` | `[ ]` | Profiles every host takes. |
| `modules.{nixos,darwin,home}` | from `modules/` | Modules every host of that kind imports. |
| `channels.<name>.{input,config,overlays}` | `nixpkgs` = `inputs.nixpkgs` | nixpkgs channels; `overlays` is a function of every channel. |
| `defaultChannel` | `"nixpkgs"` | The channel of a host that names none, and the nixpkgs Clan builds machines with. |
| `channelsConfig` | `{ }` | nixpkgs config shared by all channels. |
| `sharedOverlays` | `[ ]` | Overlays applied to every channel. |
| `specialArgs.{global,nixos,darwin,home}` | `{ }` | Extra module arguments. |
| `homeManager.enable` | `true` | Add home-manager to NixOS and nix-darwin hosts. |
| `sops.enable` | `false` | Add sops-nix to NixOS, nix-darwin and home-manager. |
| `pinInputs.registry` | `false` | Put every flake input into the machines' Nix registry. |
| `pinInputs.nixPath` | `false` | Link every input to `/etc/nix/inputs/<name>` and point NIX_PATH there. |
| `exportModules` | `false` | Expose `nixosModules`, `darwinModules` and `homeModules` (`default` and `profile-<name>`). |
| `inputs.{home-manager,nix-darwin,sops-nix}` | your input of that name, else Soxin's | The frameworks the fleet is built with. |
| `checks.hosts` | `true` | The evaluation checks. |

## Parity

`soxin-parity` (`nix run github:SoxinOS/soxin/v2#parity`) proves that a
fleet builds the same after a change of framework, or any other refactoring:
it evaluates each host's derivation in a baseline flake and in a target
flake, runs [nix-diff](https://github.com/Gabriella439/nix-diff) on the pair
and lists the causes of each difference (an environment variable, an input,
a source, the builder) while skipping what merely follows from a changed
store path. Nothing is built, so a Mac can compare Linux hosts.

```sh
nix run github:SoxinOS/soxin/v2#parity -- \
  --baseline github:me/my-fleet/<old-rev> --target . \
  --hosts example-server,example-laptop \
  --accepted ./parity-accepted.toml
```

A host is compared at its toplevel (or a home's activation package) unless
`--host NAME=ATTR` names another attribute. `--baseline-override-input` and
`--target-override-input` override an input on either side, and
`--baseline-drv NAME=PATH` takes a host's baseline from a derivation or a
built system such as `/run/current-system`. It exits 1 when any host has a
difference the fleet has not accepted.

Accepted differences live in the fleet's own TOML file, each with its reason:

```toml
[[difference]]
hosts = ["example-server"]   # optional; every host when left out
derivation = "etc"           # the derivation's name, a glob
what = "env"                 # env, input, source, builder, arguments, platform, structure
key = "nixPath"              # env variable, input or source name, a glob
changed = "^nixpkgs="        # optional: every changed line must match
reordered = true             # optional: lines only moved, none added or removed
reason = "NIX_PATH now points at the flake's own nixpkgs"
```

## The guard

`soxin-guard` fails when a repository carries private material:

- flake inputs that are not publicly fetchable: `path:`, `git+file:`,
  `git+ssh:`, `ssh:`, registry references, anything not on a public forge;
- secrets files: `*.sops.*`, private keys, sops- or age-encrypted payloads and
  other well-known secret file names;
- a `hosts/` or `machines/` directory outside `examples/`;
- the planning directory of a spec-driven workflow (its `designs/`
  directory), which belongs in a private branch;
- words of a denylist you supply from **outside** the repository.

The denylist is a file of words, one per line, given with `--denylist FILE` or
the `SOXIN_GUARD_DENYLIST` environment variable, or words in
`SOXIN_GUARD_DENYLIST_WORDS` separated by newlines or commas. An entry
starting with `!` is an exception: a phrase containing a denied word that is
allowed anyway, for a public project named like one of your hosts. A denylist
file inside the repository is refused, and findings print a word's number in
the list, never the word itself.

```sh
SOXIN_GUARD_DENYLIST=~/private/soxin-denylist nix run .#guard -- --history origin/main..HEAD
```

`nix flake check` runs the guard without a denylist (a denylist would end up in
the Nix store, and from there possibly in a binary cache) together with its
fixture test. The `guard` workflow runs it with the denylist from the
`SOXIN_GUARD_DENYLIST_WORDS` repository secret.

## Licence

MIT, see [LICENSE](LICENSE). Files carry [REUSE](https://reuse.software)
headers.
