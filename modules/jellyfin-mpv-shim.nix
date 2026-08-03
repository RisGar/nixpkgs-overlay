{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) typeOf stringLength;
  jsonFormat = pkgs.formats.json { };
  cfg = config.services.jellyfin-mpv-shim;

  renderOption =
    option:
    rec {
      int = toString option;
      float = int;
      bool = lib.hm.booleans.yesNo option;
      string = option;
    }
    .${typeOf option};

  renderOptionValue =
    value:
    let
      rendered = renderOption value;
      length = toString (stringLength rendered);
    in
    "%${length}%${rendered}";

  renderOptions = lib.generators.toKeyValue {
    mkKeyValue = lib.generators.mkKeyValueDefault { mkValueString = renderOptionValue; } "=";
    listsAsDuplicateKeys = true;
  };

  renderBindings =
    bindings: lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "${name} ${value}") bindings);

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  meta.maintainers = [ lib.maintainers.repparw ];
  disabledModules = [ "services/jellyfin-mpv-shim.nix" ];

  options = {
    services.jellyfin-mpv-shim = {
      enable = lib.mkEnableOption "Jellyfin mpv shim";

      package = lib.mkPackageOption pkgs "jellyfin-mpv-shim" { };

      settings = lib.mkOption {
        inherit (jsonFormat) type;
        default = { };
        example = {
          allow_transcode_to_h265 = false;
          always_transcode = false;
          audio_output = "hdmi";
          auto_play = true;
          fullscreen = true;
          player_name = "mpv-shim";
        };
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/jellyfin-mpv-shim/conf.json`.
          See <https://github.com/jellyfin/jellyfin-mpv-shim#configuration>
          for the configuration documentation.
        '';
      };

      additionalMpvConfig = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.attrsOf (
            lib.types.either lib.types.str (
              lib.types.either lib.types.int (lib.types.either lib.types.bool lib.types.float)
            )
          )
        );
        default = null;
        example = {
          profile = "gpu-hq";
          force-window = true;
        };
        description = ''
          Additional mpv configuration options to use for jellyfin-mpv-shim.
          These are appended to the configuration in {option}`programs.mpv.config`.
        '';
      };

      additionalMpvBindings = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
        default = null;
        example = {
          WHEEL_UP = "seek 10";
          WHEEL_DOWN = "seek -10";
        };
        description = ''
          Additional mpv input bindings to use for jellyfin-mpv-shim.
          These are appended to the configuration in {option}`programs.mpv.bindings`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.jellyfin-mpv-shim" pkgs (
        lib.platforms.linux ++ lib.platforms.darwin
      ))
    ];

    xdg.configFile =
      let
        mergedMpvConfig =
          config.programs.mpv.config
          // (if cfg.additionalMpvConfig != null then cfg.additionalMpvConfig else { });
        mergedMpvBindings =
          config.programs.mpv.bindings
          // (if cfg.additionalMpvBindings != null then cfg.additionalMpvBindings else { });
      in
      {
        "jellyfin-mpv-shim/mpv.conf" = lib.mkIf (mergedMpvConfig != { }) {
          text = renderOptions mergedMpvConfig;
        };

        "jellyfin-mpv-shim/input.conf" = lib.mkIf (mergedMpvBindings != { }) {
          text = renderBindings mergedMpvBindings;
        };
      };

    systemd.user.services.jellyfin-mpv-shim = lib.mkIf (!isDarwin) {
      Unit = {
        Description = "Jellyfin mpv shim";
        Documentation = "https://github.com/jellyfin/jellyfin-mpv-shim";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package}";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    launchd.agents.jellyfin-mpv-shim = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = [ "${lib.getExe cfg.package}" ];
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Interactive";
        StandardOutPath = "${config.home.homeDirectory}/.cache/jellyfin-mpv-shim.log";
        StandardErrorPath = "${config.home.homeDirectory}/.cache/jellyfin-mpv-shim.err.log";
        EnvironmentVariables = {
          PATH = "${lib.makeBinPath [ cfg.package pkgs.mpv ]}:/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };
    };

    # Yoinked from programs/zed-editor.nix
    # jellyfin-mpv-shim can't load the configuration file if it's not
    # writeable. So we merge the settings defined here in Nix with the existing
    # configuration, if any.
    home.activation.jellyfinMpvShimSettingsActivation =
      let
        path = lib.escapeShellArg "${config.xdg.configHome}/jellyfin-mpv-shim/conf.json";
        staticSettings = lib.escapeShellArg (jsonFormat.generate "jellyfin-mpv-shim-conf" cfg.settings);
        cmd = "${lib.getExe pkgs.jq} -s '.[0] * .[1]' ${path} ${staticSettings}";
      in
      lib.mkIf (cfg.settings != { }) (
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          run mkdir -p "$(dirname ${path})"
          if [ ! -e ${path} ]; then
            # Create the file
            if [[ -v DRY_RUN ]]; then
              run echo '{}' '>' ${path}
            else
              echo '{}' > ${path}
            fi
          fi
          if [[ -v DRY_RUN ]]; then
            run ${cmd} '>' ${path}
          else
            config="$(${cmd})"
            printf '%s\n' "$config" > ${path}
          fi
        ''
      );
  };
}
