---
feature: themes
start-date: 2021-03-21
author:
  - Marc 'risson' Schmitt
related-issues: None
---

# Summary
[summary]: #summary

This RFC describes how the Soxin project will be structured. The goal is to
avoid past mistakes made in trying to create a similar project. The attitude
we are trying to adopt is not assuming anything about a user's background,
workflow, preferences, all while keeping a sane set of proposed default
settings.

This RFC describes how themes are to be implemented in Soxin. This breaks down
in two areas:

* How themes are defined, i.e. how to define the elements required so each
  program can use the themes.
* How the user can select a default theme for all of their programs, and how
  they can be overridden for a single program.

# Motivation
[motivation]: #motivation

As Soxin is aimed at providing its users with easy-to-configure software, while
allowing for great customization, an RFC describing how such an important
feature integrates with the project was needed.

# Detailed design
[design]: #detailed-design

## Themes definition

Themes would be defined in a module named `soxin.themes`. Each theme, would be
an attribute set in this module:

```
soxin.themes = {
  darkExample = { /* ... */ };
  lightExample = { /* ... */ };
}
```

This allows Soxin to provide default themes, while leaving the opportunity to
its users to define their own themes.

The attribute set associated with a theme **must** contain a key for each
program that uses themes. The value associated to those programs should be an
attribute set (or `null`) that defines whatever is needed for the program to
implement the theme. For instance, it could be a plugin for that program that
installs a collection of themes, plus some extra configuration to choose one
theme. Having an attribute set also allows for easy evolution. The value
associated to a program can also be `null`, as a theme might not be available
for a program. It also allows for a user to define a theme for only one
program, and to override the theme for that program only, without having to
redefine it for all programs. A program with a theme value of `null` shall not
do anything related to theming.

Whether this design will or will not use modules is left unclear as
implementation detail.

## User interaction

### Globally

Following RFC 1, a `soxin.settings.theme` option would be introduced to allow
the user to choose a theme. The only permitted values here shall be the defined
themes in `config.soxin.themes`. This option shall be of type `str`, and have
an `apply` function that will lookup the theme from `config.soxin.themes` to
allow modules to directly use it without having to duplicate the lookup code.

### Per-program

Each program that uses themes must provide a `soxin.programs.<program>.theme`
option to allow the user to override a theme by program. This option will
default to `config.soxin.settings.theme`, and thus will be of type `attrs`.
However, that would make it harder for the user to override the theme, so it
will also allow `str` and have an `apply` function that will lookup the theme
from `config.soxin.themes`.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Here's how one could define two themes implementing only the `neovim` program:

```
{ pkgs, ... }:

{
  config.soxin.themes = {
    gruvbox = {
      neovim = {
        plugins = [ pkgs.neovim.gruvboxTheme ];
        extraRC = ''
          set background=dark
          colorscheme gruvbox
          let g:airline_theme='gruvbox'
        '';
      };
    };

    solarized = {
      neovim = null;
    };
  };
}
```

Here's how this would be implemented on the program side:

```
{ config, lib, ... }:

let
  cfg = config.soxin.programs.neovim;
  themeRC = cfg.theme.extraRC ? "";
  themePlugins = cfg.theme.plugins ? [];
{
  config.program.neovim = lib.mkIf soxin.programs.neovim.enable {
    enable = true;
    configure = ''
      /* Some configuration */
      ${themeRC}
    '';

    plugins = [ /* Some plugins */ ] ++ themePlugins;
  };
}
```

The options of the `programs.neovim` have been modified for simplicity's sake.

# Drawbacks
[drawbacks]: #drawbacks

This presents some additional complexity compared to how this was implemented
in Shabka.

# Alternatives
[alternatives]: #alternatives

* A module that defines configuration for each module, instead of the modules
  looking up what they need, as it was done in Shabka. The main drawback for
  this is that it does not provide the ability to customize as much as Soxin
  intends to.

# Unresolved questions
[unresolved]: #unresolved-questions

###### Should a theme definition be a submodule?

This allows for less code to be written, as each program's theme definition
would default to `null`, but it adds complexity.

###### Should a program's theme definition be a submodule?

This allows for less code to be written, as each program's theme definition
would default to `null`, but it adds complexity. This is particularly visible
in the `neovim` example above, where neovim has to define two variables
(`themeRC` and `themePlugins`), that could just be defaults if we were using
submodules.

Those two questions will be answered once we try out some implementations.

# Future work
[future]: #future-work

* Overriding themes for each module is troublesome, as a lot of code might be
  duplicated. As such, we need a pattern to easily create modules with all the
  required common things.
