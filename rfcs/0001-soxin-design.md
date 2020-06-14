---
feature: soxin design
start-date: 2020-05-21
author:
  - Marc 'risson' Schmitt
  - Wael Nasreddine
related-issues: None
---

# Summary
[summary]: #summary

This RFC describes how the Soxin project will be structured. The goal is to
avoid past mistakes made in trying to create a similar project. The attitude
we are trying to adopt is not assuming anything about a user's background,
workflow, preferences, all while keeping a sane set of proposed default
settings.

# Motivation
[motivation]: #motivation

Soxin's goal is to provide an easy way for newcomers to use Nix and related
technologies, such as NixOS, home-manager and nix-darwin. This will include,
but is not limited to, default configuration for widely used programs, a start
guide on how to get started and hopefully an installer.

# Detailed design
[design]: #detailed-design

To achieve all those goals and stay in line with the core principles we set,
a clear design is necessary.

## Global settings

Some settings are meant to be set globally for a system, such as keyboard
layout(s), theme, fonts and programming languages used. As such, Soxin will
provide a way to set those under the `soxin.settings` module. Those settings
will be used by all programs and services that require them. However, some
users might want to override those settings on a per-program basis. As such,
Soxin must provide a library function that is used to create a module, with
the same global settings but only for that module. Those module-scoped settings
will default to the global ones. For instance, this library function could look
like:

```
mkSoxinModule = { config, name, extraOptions ? { } }: lib.recursiveUpdate {
  enable = mkEnableOption name;

  keyboardLayout = mkOption {
    type = layoutModule; # see the keyboard module for an explanation of this
    default = config.soxin.settings.keyboard.defaultLayout;
    description = "Keyboard layout to use for ${name}";
  };
} extraOptions;
```

and be used like:

```
options = {
  soxin.programs.neovim = mkSoxinModule {
    inherit config;
    name = "neovim";
    extraOptions = {
      /* ... */
    };
  };
};

config = {
  programs.neovim.keyboard = config.soxin.programs.neovim.keyboardLayout.layout;
}
```

This allows the user to not set anything and just use the default layout they
set globally, but they can also override that setting only for neovim.

## Modules and alternative software

A Soxin module should not assume the use of a particular software. For
instance, one user will want to use `bash`, another one `zsh`. Soxin thus shall
provide the `programs.shell` module with global options like
`programs.shell.aliases` and software-specific options like
`programs.shell.zsh.enable` and `programs.shell.bash.enable`. To define a
default shell, Soxin shall provide a `programs.shell.defaultShell` option that
each software-specific module will set with `mkDefault`. If a user chooses to
enable multiple shells, an error will occur and they will have to set that
option.

This is not a hard requirement, as we will not provide several software
alternatives at the start of this project. Migration from a single software to
a many software setup shouldn't be hard as we can just rename the options.
