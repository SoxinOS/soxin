---
feature: tools-and-programming-languages
start-date: 2021-04-30
author: Shahrukh Khan
related-issues: None
---

# Summary
[summary]: #summary

This RFC describes how tools and programming languages support is to be
implemented in Soxin. This breaks down in two areas:

* How languages are defined, i-e how to define the language and its properties
  i-e its compiler, tools, editor plugins etc. How the user can define the
  default plugins for a language in their editor(s).
* How the user can select default set of languages and its required tools in
  their editor, and how to override default settings per-editor.

# Motivation
[motivation]: #motivation

As Soxin is aimed at providing its users with easy-to-configure software, while
allowing for great customization, an RFC describing how such an important
feature integrates with the project was needed.

# Detailed design
[design]: #detailed-design

## Language definition

Languages would be defined in a module named `soxin.programmingLanguagesModules`.
Each language, would be an attribute set in this module:

```
soxin.programmingLanguagesModules = {
  go = { /* ... */ };
  java = { /* ... */ };
  python = { /* ... */ };
}
```
## Tools defination

Programming tools will be defined in a module named `soxin.toolsModules`.
Each tool will be an attribute set in this module.

```
soxin.toolsModules = {
  git = { /* ... */ };
  tmux = { /* ... */ };
}
```
This allows Soxin to define its own support for languages and tools, while
allowing room for user customization as well.

Similar to RFC 2, each programming language must include a key for each editor
which will support that language.  For instance, it could be a plugin for that
editor that installs support for that language, plus some extra configuration
to configure that plugin.

## User interaction

### Globally

Similar to RFC 2, a `soxin.settings.programmingLanguages` and
`soxin.settings.tools` option would be introduced to allow the user
to choose their programming stack. The only permitted values here shall be the
defined in `config.soxin.<programmingLanguages/tools>`. This option shall be of type
`Array` of `str`, with apply function which iterate over the array and find
appropriate languages or tools.

### Per-program

Each program that supports a language must provide a
`soxin.programs.<program-name>.programmingLanguages` and
`soxin.programs.<program-name>.tools` option to allow the user to
override the programming language stack and tools settings per program. These options will default
to `config.soxin.settings.<programmingLanguages/tools>`, and thus will be of type `listOf`
`attrs`. Similar to RFC 2, they will also have will also allow `str` and have
an `apply` function that will lookup the programmingLanguage/tools config from `config.soxin.<programmingLanguages/tools>`
for each option.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Here's how one could define a language and a tool implementing only the `neovim`
editor:

```
# ProgrammingLanguages

{ mode, config, pkgs, lib, soxin, ... }:

with lib;
{
  config.soxin.programmingLanguagesModules.go = (mkMerge [
    {
      neovim = {
        plugins = [ pkgs.neovim.go ];
        extraRC = ''
        '';
      };
    }

    /*(optionalAttrs (mode == "home-manager") {
      programs.go = {
      enable = true;
      };
      })*/
  ]);
}

#tools
{ mode, config, pkgs, lib, soxin, ... }:

with lib;
{
  config.soxin.toolsModules.git = (mkMerge [
    {
      neovim = {
        plugins = [ pkgs.neovim.fugitive ];
        extraRc = ''
        '';
      };
    }

    /*(optionalAttrs (mode == "home-manager") {
      programs.go = {
      enable = true;
      };
      })*/
  ]);
}
```

Here's how this would be implemented on the editor side:

```
{ mode, config, pkgs, lib, soxin, ... }:

with lib;
let
  cfg = config.soxin.programs.neovim;
in
{
  options = {
    soxin.programs.neovim = soxin.lib.mkSoxinModule {
      inherit config;
      name = "neovim";
      includeProgrammingLanguages = true;
      includeTools = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "home-manager") {
      programs.neovim = mkMerge [
        { inherit (cfg) enable; }

        {
          plugins = flatten (map
            (v:
              v.extensions
            )
            cfg.programmingLanguages ++ cfg.tools);
        }

      ];
    })
  ]);
}
```

The options of the `programs.neovim` have been modified for simplicity's sake.


# Drawbacks
[drawbacks]: #drawbacks

Adds additional layer of segregation between `soxin.programs` and
`soxin.tools`. Which will require Soxin developers to be cognizant
about where to add a new language or a tool, thus adding additional layer of
complexity.

# Alternatives
[alternatives]: #alternatives


# Unresolved questions
[unresolved]: #unresolved-questions


