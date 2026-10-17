<!--
SPDX-FileCopyrightText: 2026 Wael Nasreddine
SPDX-License-Identifier: MIT
-->

# Soxin

Soxin is a public Nix framework for running a fleet of machines: NixOS
systems, nix-darwin systems and standalone home-manager configurations,
declared as a directory of hosts and profiles and deployed with deploy-rs.

It is a [flake-parts](https://flake.parts) module built on plain
`nixpkgs.lib.nixosSystem`, nix-darwin's `darwinSystem` and home-manager's
`homeManagerConfiguration`, plus a thin `lib.mkFleet` wrapper for flakes that
do not use flake-parts themselves.

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
├── hosts/
│   ├── example-server/
│   │   ├── host.nix            # kind, system, profiles, modules, deploy
│   │   └── configuration.nix
│   ├── example-laptop/
│   │   └── host.nix
│   └── example-devbox/
│       └── host.nix
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

- **`hosts/<name>/host.nix`** declares one host. It is a module (an attribute
  set, or a function of `{ inputs, name, ... }`):

  ```nix
  {
    kind = "nixos";            # "nixos", "darwin" or "home-manager"
    system = "x86_64-linux";
    channel = "nixpkgs";       # optional, defaults to fleet.defaultChannel
    profiles = [ "server" ];   # on top of fleet.defaultProfiles
    modules = [ ./configuration.nix ];
    specialArgs = { };         # optional, extra module arguments

    deploy = {                 # optional; a host with a hostname gets a deploy-rs node
      hostname = "example-server.example.com";
      sshUser = "alice";
    };
  }
  ```

  `nixos` hosts become `nixosConfigurations.<name>`, `darwin` hosts
  `darwinConfigurations.<name>` and `home-manager` hosts
  `homeConfigurations.<name>`.

- **`profiles/<name>/`** holds a `nixos.nix`, `darwin.nix` and/or `home.nix`
  (or `nixos/`, `darwin/`, `home/` directories). A host that takes the profile
  gets the file for its kind; `home.nix` also reaches home-manager inside
  NixOS and nix-darwin hosts.

- **`modules/`** holds the fleet's own `nixos.nix`, `darwin.nix` and
  `home.nix`, imported by every host of that kind.

Every module receives these arguments besides the usual ones: `inputs` (the
fleet flake's inputs), `soxin`, `hostName`, `channels` (every channel's
packages for the host's system) and `mode` (`"NixOS"`, `"nix-darwin"` or
`"home-manager"`), plus whatever `fleet.specialArgs` and the host add.

The framework also produces `deploy.nodes` for deploy-rs, a `host-<name>`
check per host that evaluates it, and a `deploy-schema` check.

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
same options under `fleet`.

`nix flake init -t github:SoxinOS/soxin/v2` copies the [example
fleet](examples/fleet): one NixOS, one nix-darwin and one standalone
home-manager host, all made up.

### Options

| Option | Default | |
| --- | --- | --- |
| `root` | `null` | The fleet directory; `hostsDir`, `profilesDir` and `modulesDir` default to its subdirectories. |
| `hosts.<name>` | from `hosts/` | Hosts; see `host.nix` above. |
| `profiles.<name>.{nixos,darwin,home}` | from `profiles/` | Profiles as lists of modules. |
| `defaultProfiles` | `[ ]` | Profiles every host takes. |
| `modules.{nixos,darwin,home}` | from `modules/` | Modules every host of that kind imports. |
| `channels.<name>.{input,config,overlays}` | `nixpkgs` = `inputs.nixpkgs` | nixpkgs channels; `overlays` is a function of every channel. |
| `defaultChannel` | `"nixpkgs"` | The channel of a host that names none. |
| `channelsConfig` | `{ }` | nixpkgs config shared by all channels. |
| `sharedOverlays` | `[ ]` | Overlays applied to every channel. |
| `specialArgs.{global,nixos,darwin,home}` | `{ }` | Extra module arguments. |
| `homeManager.enable` | `true` | Add home-manager to NixOS and nix-darwin hosts. |
| `sops.enable` | `false` | Add sops-nix to NixOS, nix-darwin and home-manager. |
| `inputs.{home-manager,nix-darwin,deploy-rs,sops-nix}` | your input of that name, else Soxin's | The frameworks the fleet is built with. |
| `checks.hosts`, `checks.deploySchema` | `true` | The evaluation and deploy-rs schema checks. |

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
