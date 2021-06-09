# soxin

### How to get started

First, you'll need your own personal repository to store your configurations.
To get one that already has a few things setup you can run the following:

```
$ mkdir soxincfg && cd soxincfg
$ git init
$ nix flake init -t github:soxinos/soxin
```

To build and run the provided configuration, you can do this:

```
$ nixos-rebuild --flake .#minimal-nixos-system build-vm
```

## Acknowledgments

Here is a list of the tools we are using for this project. If licensed code was
borrowed, its license is kept with it.

* [nixflk](https://github.com/nrdxp/nixflk) for the general project structure.
* [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt) for source code
  formatting.
* [flake-utils-plus](https://github.com/gytis-ivaskevicius/flake-utils-plus)
  for building the systems.
