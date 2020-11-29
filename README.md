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
$ nixos-rebuild --flake .#example build-vm
$ ./result/bin/run-example-vm
```
