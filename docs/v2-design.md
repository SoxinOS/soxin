<!--
SPDX-FileCopyrightText: 2026 Wael Nasreddine
SPDX-License-Identifier: MIT
-->

# Soxin v2: design and decisions

Soxin v2 is a public framework for running a fleet of machines. A private
fleet flake (hosts, profiles, private modules, secrets) consumes it, and the
framework never references any consumer: dependencies point one way,
private -> public.

This file records the decisions taken while building v2 and why.

## Scope of the v2 branch

- **v2 is branched from `main`, and v1 stays there untouched.** The worktree's
  own branch carried one extra v1 fix that is not on `main`; v2 starts from
  `main` as asked.
- **The v2 tree holds the framework only.** v1's `lib/`, `modules/`, `pkgs/`,
  `template/` and `rfcs/` are removed from the v2 branch (they live on in
  `main` and in history). They were built around `mkSoxinModule` and
  flake-utils-plus and would need porting; porting modules is a later task.
  Kept: `LICENSE`, `.envrc`, `.gitignore` (rewritten), `README.md` (rewritten).

## The framework

- **flake-parts module first, `lib.mkFleet` second.** The module
  (`flakeModules.default`, also `flakeModules.fleet`) is the real interface, so
  a fleet can add its own packages, dev shells and checks with ordinary
  flake-parts modules. `lib.mkFleet` is a wrapper that calls
  `flake-parts.lib.mkFlake` with the module imported and passes every other
  argument to the `fleet` options; its `imports` argument takes extra
  flake-parts modules.
- **The name `mkFleet` is kept.** It says what it builds (a fleet's flake
  outputs), is distinct from v1's `mkFlake` so the two cannot be confused while
  consumers migrate, and matches the `fleet` option namespace.
- **Options are the source of truth; the directory only fills them.**
  `fleet.hosts`, `fleet.profiles` and `fleet.modules` are ordinary options.
  `fleet.root` (or `hostsDir`, `profilesDir`, `modulesDir`) discovers values
  for them, so a fleet can also declare hosts inline, mix both, or override
  one discovered value. Errors from a host file point at that file, because a
  host file is imported as a module of the host submodule.
- **A host is `hosts/<name>/host.nix`, not `default.nix`.** `default.nix` reads
  as "a NixOS module" to most people; `host.nix` is clearly the host's
  declaration, and the directory is free for `configuration.nix`,
  `hardware-configuration.nix`, `home.nix` and so on. A directory under
  `hosts/` without `host.nix` is an error rather than silently skipped.
- **`host.nix` is a module.** It can be an attribute set or a function taking
  `inputs` and `name` (as in `examples/fleet/hosts/example-devbox`), and its
  options are typed: `kind` is an enum of `nixos`, `darwin`, `home-manager`.
- **Profiles and the fleet's modules are split by kind by file name**:
  `nixos.nix`, `darwin.nix`, `home.nix` (or `nixos/`, `darwin/`, `home/`
  directories). There is no "common to all kinds" file: NixOS, nix-darwin and
  home-manager options differ, and v1's habit of switching on `mode` inside
  one module made those modules hard to read. `home.nix` reaches both
  standalone home-manager hosts and home-manager inside NixOS and nix-darwin
  hosts (via `home-manager.sharedModules`), so a profile like `workstation`
  can carry user settings once.
- **Profiles are taken by name** (`profiles = [ "server" ]`), plus
  `fleet.defaultProfiles` for every host (v1's "core" profile). An unknown name
  is an error naming the host and the profile.
- **Channels.** `fleet.channels.<name> = { input; config; overlays; }`.
  `overlays` is a function from every channel of the same system to a list of
  overlays, so `nixpkgs` can take packages from `nixpkgs-unstable` (v1's
  `overlaysBuilder`). Channels are instantiated once per system and shared by
  all hosts of that system. `fleet.channelsConfig` and `fleet.sharedOverlays`
  apply to every channel. A `nixpkgs` channel defaults to `inputs.nixpkgs`.
  A host's NixOS and nix-darwin modules come from its own channel's input
  (`<channel>.lib.nixosSystem`, and `lib` passed to `darwinSystem`), so a host
  on another channel gets that channel's modules too. Channel patches (v1 via
  flake-utils-plus) are not supported; see open questions.
- **Packages are passed in, not configured inside.** Hosts get
  `nixpkgs.pkgs` set to their channel's instance. This is what lets the
  overlays and config live in one place for the whole fleet; the price is that
  `nixpkgs.config` and `nixpkgs.overlays` inside host modules have no effect.
- **The frameworks come from the fleet when it has them.**
  `fleet.inputs.{home-manager,nix-darwin,deploy-rs,sops-nix}` default to the
  fleet's input of the same name, else to the one Soxin pins. A fleet thus
  controls those versions simply by having the input, without `follows`
  gymnastics, and a fleet that does not care gets working defaults. The flake
  inputs are fetched lazily, so a fleet without darwin hosts never fetches
  nix-darwin.
- **Module arguments.** Every module gets `inputs`, `soxin`, `hostName`,
  `channels` and `mode`. `mode` keeps v1's values (`"NixOS"`, `"nix-darwin"`,
  `"home-manager"`) so existing modules that switch on it keep working while
  they are ported. `fleet.specialArgs.{global,nixos,darwin,home}` and a host's
  `specialArgs` add more (e.g. nixos-hardware, nixos-wsl). Later ones win:
  framework arguments, then global, then per kind, then per host.
- **home-manager inside NixOS and nix-darwin is on by default**
  (`fleet.homeManager.enable`), with `useGlobalPkgs` and `useUserPackages`
  defaulted to true as in v1. Standalone home-manager hosts are
  `kind = "home-manager"`.
- **sops-nix is opt-in** (`fleet.sops.enable`) and adds the module to NixOS,
  nix-darwin and home-manager (standalone and inside systems) at once.
  Secrets files themselves stay in the fleet.
- **deploy-rs nodes are per host and opt-in by `deploy.hostname`.** The
  profile path is derived from the host's kind (`activate.nixos`,
  `activate.darwin`, `activate.home-manager`), `user` defaults to root for
  systems and must be set for home-manager hosts, and `deploy.settings` passes
  anything else through.
- **Checks build nothing heavy.** deploy-rs's own `deployChecks` build every
  node's closure, which a machine of another system cannot do (a macOS
  workstation checking a Linux server). Instead:
  - `host-<name>` per host evaluates the host down to its toplevel (or
    activation package) derivation and writes its path to a file;
  - `deploy-schema` validates the nodes against deploy-rs's `interface.json`
    with the store paths replaced by their (unbuilt) derivation paths.

  Both exist on every system, so `nix flake check` on any machine evaluates
  every host.
- **perSystem `pkgs` is the default channel**, overlays included, so a fleet's
  own perSystem modules see the same packages as its hosts.
- **Systems.** Soxin and `mkFleet` default to `x86_64-linux`, `aarch64-linux`
  and `aarch64-darwin`. `x86_64-darwin` is left out as nixpkgs is phasing it
  out; a fleet can still pass `systems`, and a host's own system is always
  supported regardless.
- **Pinned to the 26.05 releases** (nixpkgs `nixos-26.05`, home-manager
  `release-26.05`, nix-darwin `nix-darwin-26.05`), with sops-nix, deploy-rs and
  flake-parts following Soxin's nixpkgs.
- **Not carried over from v1:** NUR in every channel (a fleet adds it as an
  overlay if it wants it), the Soxin package set and overlay, the generated
  dev shell, NIX_PATH and registry generation from inputs (flake-utils-plus),
  and the pre-commit-hooks input. These are fleet choices, not framework
  mechanism; see open questions for the registry.

## The example fleet

- `examples/fleet` has one NixOS host (`example-server`, with a deploy-rs node),
  one nix-darwin host (`example-laptop`) and one standalone home-manager host
  (`example-devbox`, with a deploy-rs node), three profiles, the fleet's own
  modules, two channels with an overlay taking a package from unstable, sops
  enabled, and a global special argument. Users and addresses are made up
  (`alice`, `example.com`).
- **The fleet's settings are in `fleet.nix`, apart from `flake.nix`.** The
  example's `flake.nix` is what a consumer writes (and the flake template). Its
  inputs point at the published Soxin, which a check cannot use, so Soxin's
  checks import `fleet.nix` and evaluate it with Soxin's own inputs, with
  Soxin itself as `soxin` and Soxin's nixpkgs standing in for unstable (no
  second nixpkgs to fetch). Every example check appears as `example-<check>`.
- The example has no `flake.lock`: it would lock the published v2, which does
  not exist yet. `.gitignore` keeps one out.

## The guard

- **One tool, `soxin-guard`** (Python, standard library only), exposed as
  `packages.guard` and `apps.guard`. It checks:
  - inputs: every `flake.lock` node (`locked` and `original`) and every `url`
    and `type` in every `flake.nix`. github, gitlab and sourcehut references
    pass unless they name a `host` that is not public; git, tarball, file and
    hg inputs must be https URLs on a known public forge; `path`, `indirect`
    (registry) and unknown types fail, as do `git+file`, `git+ssh`, `ssh` and
    scp-like remotes. `--allow-host` adds a forge.
  - secrets: file names (`*.sops.*`, `.sops.yaml`, `*.age`, `*.pem`, `*.key`,
    ssh key names, `.env`, `.netrc`, ...) and contents (private key blocks,
    age secret keys, sops-encrypted values, age-encrypted files).
  - `hosts/` and `machines/` directories anywhere except under `examples/`.
  - the planning directory of a spec-driven workflow (its `designs/`
    directory), anywhere: planning notes are kept in a private branch and
    the public branch is cut without them. The tool's name is assembled from
    pieces in the guard and its fixtures, so a denylist may contain it.
  - denylist words, case-insensitive, in paths and contents, and with
    `--history <range>` in the messages, authors, file names and added lines
    of the range's commits (a word added and removed again is still in
    history). Removed lines are skipped: they were in history before the
    range, and removing them is how a leak gets fixed. Author fields are
    scanned too, so a denylist should not name the address commits are
    authored with.
- **The denylist never lives in the repository.** It comes from
  `--denylist FILE`, `SOXIN_GUARD_DENYLIST` (a file) or
  `SOXIN_GUARD_DENYLIST_WORDS` (words). A denylist file inside the checked
  repository is refused.
- **Denylist exceptions.** Matching is a case-insensitive substring search, so
  a private host that shares its name with a public project (for instance an
  organisation in one of Soxin's own input URLs) would flag Soxin itself. An
  entry starting with `!` names an allowed phrase; it is blanked out before
  the denied words are searched. Exceptions live in the same outside file.
- **Findings never print a denylist word**, only its number in the list, and
  file names containing one are masked the same way, so the guard can run in a
  public CI log.
- **`nix flake check` runs the guard without the denylist.** Flake checks are
  pure, so the only ways in are `--impure` plus putting the words into a
  derivation, and that writes them into the Nix store and, from there, into
  any binary cache the checks are pushed to. Hashing the words does not help
  enough (short names are easy to brute-force). So the flake check covers
  inputs, secrets, hosts and planning directories; the denylist is applied by `nix run .#guard`
  locally and by the `guard` CI workflow from a repository secret.
- **The fixture test builds its fixtures at run time** in a temporary
  directory. Committed fixtures would contain a `hosts/` directory, secrets
  files and private-key headers, which the guard on this very repository
  rejects. It covers each failure (git+ssh, git+file, path, private forge,
  private gitlab, indirect, locked path/ssh/file/tarball inputs, `*.sops.*`,
  `.sops.yaml`, ssh key names, private key, sops and age contents, top-level
  and nested `hosts/`, top-level `machines/`, a planning `designs/`
  directory (also under `examples/`), denylist by flag, file variable and word variable,
  denylist in a file name, a word inside and outside an exception, a
  denylist inside the repo, `--require-denylist`,
  a word only in history, a range that only removes a word, a word in a
  commit message) and the passes (clean
  repo, clean repo with a denylist, an allowed extra host, `machines/` under
  `examples/`, a `designs/` directory of another parent, a word removed from
  the tree without `--history`), and fails if any output contains the denied
  word. Strings that would trip the guard on its own sources (key headers,
  sops markers) are assembled from pieces.
- **CI.** `check.yml` runs `nix flake check` on Linux and macOS. `guard.yml`
  runs the guard with the `SOXIN_GUARD_DENYLIST_WORDS` secret and
  `--history origin/<base>..HEAD`. Pushes must have a denylist
  (`--require-denylist`), so a missing secret fails loudly; pull requests from
  forks get no secrets and run without it.

## Licensing

- `LICENSE` keeps its line 3 and gains `Copyright (c) 2026 Wael Nasreddine`
  under it.
- Every new file has SPDX headers naming Wael Nasreddine alone, in the file's
  comment syntax. `README.md`, `.gitignore` and `flake.nix` were rewritten from
  scratch, so they are treated as new. `flake.lock` cannot hold comments and is
  annotated in `REUSE.toml`. `.envrc` is kept as it was and is annotated in
  `REUSE.toml` with the copyright lines of `LICENSE`, as it predates v2.
- `LICENSES/MIT.txt` is a symlink to `LICENSE`, which REUSE needs to find the
  licence text; it adds no text of its own.
- A `reuse` check runs `reuse lint` in `nix flake check`.

## Open questions

- **Nix registry and NIX_PATH from inputs.** v1 (via flake-utils-plus) pinned
  `nix.registry` and `NIX_PATH` to the fleet's inputs on every host. v2 leaves
  that to the fleet; it could become an opt-in option.
- **Channel patches.** v1 could patch a channel's nixpkgs. v2 cannot; a fleet
  can point a channel at a patched nixpkgs flake instead.
- **Exposing the fleet's modules** as `nixosModules` / `darwinModules` /
  `homeModules` outputs is not done; nothing needed it yet.
- **Denylist in `nix flake check`.** Kept out on purpose (see above); the
  owner may prefer an opt-in impure mode despite the store and cache exposure.
- **Example `flake.lock`.** Once v2 is published, the example could carry a
  lock and its own CI evaluation against the published framework.
