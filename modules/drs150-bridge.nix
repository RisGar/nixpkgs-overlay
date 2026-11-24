{ lib, pkgs, ... }:
{
  imports = [
    (import "${pkgs.drs150-bridge.src}/module.nix" {
      self = {
        packages = lib.genAttrs [ pkgs.stdenv.hostPlatform.system ] (_: {
          default = pkgs.drs150-bridge;
        });
      };
    })
  ];
}
