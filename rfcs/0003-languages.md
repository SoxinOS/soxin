---
feature: (languages)
start-date: (2021-04-30)
author: (Shahrukh Khan)
related-issues: (None)
---

# Summary
[summary]: #summary

This RFC describes how language support is to be implemented in Soxin. This
breaks down in two areas:

* How languages are defined, i-e how to define the language and its properties
  i-e its compiler, tools, editor plugins etc. How the user can define the
  defualt plugins for a language in his editor(s).
* How the user can select default set of languages and its required tools in
  his editor, and how to override default settings on the editor.

# Motivation
[motivation]: #motivation

As Soxin is aimed at providing its users with easy-to-configure software, while
allowing for great customization, an RFC describing how such an important
feature integrates with the project was needed.

# Detailed design
[design]: #detailed-design

## Language definition

Languages would be defined in a module named `soxin.programming.languages`.
Each language, would be an attribute set in this module:

```
soxin.programming.languages = {
  go = { /* ... */ };
  java = { /* ... */ };
  python = { /* ... */ };
}
```
## Tools defination

Programming tools will be defined in a module named `soxin.programming.tools`.
Each tool will be an attribute set in this module.

```
soxin.programming.tools = {
  git = { /* ... */ };
  tmux = { /* ... */ };
}
```
This allows soxin to define its own support for languages and tools, while
allowing room for user customization as well.

Similar to RFC 2, each programming language must include a key for each editor
which will support that language.  For instance, it could be a plugin for that
editor that installs support for that language, plus some extra configuration
to configure that plugin.

## User interaction

### Globally

Similar to RFC 2, a `soxin.settings.programming.languages` and
`soxin.settings.programming.tools` option would be introduced to allow the user
to choose his programming stack. The only permitted values here shall be the
defined in `config.soxin.programming.<type>`. This option shall be of type
`Array` of `str`, with apply function which iterate over the array and find
appropriate language or tool.

### Per-editor

Each editor that supports a language must provide a
`soxin.programs.<editor-name>.language` and `soxin.programs.<editor-name>.tool`
option to allow the user to override the programming stack settings per editor.
These options will default to `config.soxin.settings.programming.<type>`,
and thus will be of type `attrs`. Similar to RFC 2, they will also have will
also allow `str` and have an `apply` function that will lookup the theme
from `config.soxin.programming.<type>` for each option.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Here's how one could define a language and a tool implementing only the `neovim`
editor:

```
{ pkgs, ... }:

{
  config.soxin.programming.languages = {
    go = {
      neovim = {
        plugins = [ pkgs.neovim.go ];
        extraRC = ''
        '';
      };
    };

    config.soxin.programming.tools = {
      git = {
        plugins = [ pkgs.neovim.fugitive ];
        extraRc = ''
        '';
      };
    };
  };
}
```

Here's how this would be implemented on the editor side:

```
{ config, lib, ... }:

let
  cfg = config.soxin.programs.neovim;
  goSupportRc = cfg.programming.languages.go ? "";
  gitSupportRc = cfg.programming.tools.git ? "";
  goSupportPlugins = cfg.programming.languages.go.plugins ? [];
  gitSupportPlugins = cfg.programming.tools.git.plugins ? [];
{
  config.program.neovim = lib.mkIf soxin.programs.neovim.enable {
    enable = true;
    configure = ''
      /* Some configuration */
      ${goSupportRc}
      ${gitSupportRc}
    '';

    plugins = [ /* Some plugins */ ] ++ goSupportPlugins ++ gitSupportPlugins;
  };
}
```

The options of the `programs.neovim` have been modified for simplicity's sake.


# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions


# Drawbacks
[drawbacks]: #drawbacks


# Alternatives
[alternatives]: #alternatives


# Unresolved questions
[unresolved]: #unresolved-questions


# Future work
[future]: #future-work


