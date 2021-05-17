{ mode, config, pkgs, lib, soxin, ... }:

with lib;
let
  cfg = config.soxin.programs.tmux;

  # copied from home-manager
  # TODO: Move this to NixOS instead!
  pluginName = p: if types.package.check p then p.pname else p.plugin.pname;
  configPlugins = {
    assertions = [
      (
        let
          hasBadPluginName = p: !(hasPrefix "tmuxplugin" (pluginName p));
          badPlugins = filter hasBadPluginName cfg.plugins;
        in
        {
          assertion = badPlugins == [ ];
          message =
            "Invalid tmux plugin (not prefixed with \"tmuxplugins\"): "
            + concatMapStringsSep ", " pluginName badPlugins;
        }
      )
    ];

    programs.tmux.extraConfig = ''
      # ============================================= #
      # Load plugins with NixOS                       #
      # --------------------------------------------- #
      ${(concatMapStringsSep "\n\n"
      (p: ''
        # ${pluginName p}
        # ---------------------
        ${p.extraConfig or ""}
        run-shell ${
          if types.package.check p
          then p.rtp
          else p.plugin.rtp
        }
      '')
      cfg.plugins)}
      # ============================================= #
    '';
  };
in
{
  options = {
    soxin.programs.tmux = soxin.lib.mkSoxinModule {
      inherit config;
      name = "tmux";
      includeKeyboardLayout = true;
      includeTheme = true;
      extraOptions = {
        extraConfig = mkOption {
          type = types.lines;
          default = "";
          description = "Extra tmux configuration.";
        };

        plugins = mkOption {
          type = with types; listOf (either package soxin.lib.modules.tmux.pluginWithConfigModule);
          default = [ ];
          defaultText = "The plugins added by the theme";
          example = literalExample ''
            with pkgs; [
              tmuxPlugins.cpu
              {
                plugin = tmuxPlugins.resurrect;
                extraConfig = "set -g @resurrect-strategy-nvim 'session'";
              }
              {
                plugin = tmuxPlugins.continuum;
                extraConfig = '''
                  set -g @continuum-restore 'on'
                  set -g @continuum-save-interval '60' # minutes
                ''';
              }
            ]
          '';
          description = ''
            List of tmux plugins to be included at the end of your tmux
            configuration. The sensible plugin, however, is defaulted to
            run at the top of your configuration.
          '';
        };

        secureSocket = recursiveUpdate
          (mkEnableOption ''
            Store tmux socket under <filename>/run</filename>, which is more
            secure than <filename>/tmp</filename>, but as a downside it doesn't
            survive user logout.
          '')
          { default = pkgs.stdenv.isLinux; };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # add all plugins installed by themes
    { soxin.programs.tmux.plugins = cfg.theme.plugins; }

    (optionalAttrs (mode == "NixOS") (mkMerge [
      { programs.tmux = { inherit (cfg) enable extraConfig secureSocket; }; }
      (mkIf (cfg.plugins != [ ]) configPlugins)
    ]))

    (optionalAttrs (mode == "home-manager") {
      programs.tmux = { inherit (cfg) enable extraConfig plugins secureSocket; };
    })
  ]);
}
