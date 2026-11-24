{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.drs150-bridge;
  stateDir = "${config.xdg.stateHome}/drs150-bridge";
  dataDir = "${config.xdg.dataHome}/drs150-bridge";
in
{
  options.services.drs150-bridge = {
    enable = lib.mkEnableOption "the Canon DR-S150 eSCL/AirScan bridge";

    package = lib.mkPackageOption pkgs "drs150-bridge" { };

    bind = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address to listen on. Loopback by default: the endpoint has no authentication and every
        job physically pulls a sheet from the scanner.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8632;
      description = "eSCL HTTP port.";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "Canon imageFORMULA DR-S150";
      description = "Bonjour service instance name shown in Image Capture.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "services.drs150-bridge drives Canon's macOS TWAIN driver, it is darwin-only.";
      }
    ];

    home.activation.drs150-bridge-state = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${stateDir}" "${dataDir}"
    '';

    launchd.agents.drs150-bridge = {
      enable = true;
      config = {
        ProgramArguments = [ "${cfg.package}/bin/escl-server" ];
        EnvironmentVariables = {
          ESCL_BIND = cfg.bind;
          ESCL_PORT = toString cfg.port;
          ESCL_NAME = cfg.name;
          XDG_DATA_HOME = config.xdg.dataHome;
          XDG_STATE_HOME = config.xdg.stateHome;
        };
        RunAtLoad = true;
        # restart when it fails, but do not spin if it cannot bind its port
        KeepAlive = {
          SuccessfulExit = false;
        };
        ThrottleInterval = 10;
        ProcessType = "Background";
        StandardOutPath = "${stateDir}/stdout.log";
        StandardErrorPath = "${stateDir}/stderr.log";
      };
    };
  };
}
