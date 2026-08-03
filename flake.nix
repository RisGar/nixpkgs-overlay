{
  description = "Overlay for nixpkgs";
  outputs = { nix-gleam, ... }: {
    homeManagerModules.default = ./modules/jellyfin-mpv-shim.nix;
    overlays.default = final: prev: {
      jellyfin-mpv-shim = prev.callPackage ./pkgs/jellyfin-mpv-shim.nix { };
      thaw = prev.callPackage ./pkgs/thaw.nix { };
      mole-mac = prev.callPackage ./pkgs/mole-mac.nix { };
      dragterm = prev.callPackage ./pkgs/dragterm.nix { };
      walavave-trash-cli = prev.callPackage ./pkgs/walavave-trash-cli.nix { };
      create-thesis = prev.callPackage ./pkgs/create-thesis.nix { };
      ocrtool-mcp = prev.callPackage ./pkgs/ocrtool-mcp.nix { };
      nvim = prev.callPackage ./pkgs/nvim-config.nix { };
      nixln-edit = prev.callPackage ./pkgs/nixln-edit.nix { };
      print-cli-rs = prev.callPackage ./pkgs/print-cli-rs.nix { };
      nerdfont-cheatsheet = prev.callPackage ./pkgs/nerdfont-cheatsheet.nix {
        nix-gleam = nix-gleam;
      };
      # TODO: detexify-next

      logseq = (
        let
          pkgs' = import (fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/ec1c722e017dfccbb2f66a8aafbe003320266d33.tar.gz";
            sha256 = "0jws2i94asr1yish76799gmyw51dj98n8badq3snc8prifmsd3a5";
          }) { system = prev.stdenv.hostPlatform.system; };
        in
        pkgs'.logseq
      );

      signal-desktop = prev.signal-desktop.override {
        withAppleEmojis = true;
      };

      yaziPlugins = prev.yaziPlugins // {
        macos-trash = prev.callPackage (
          {
            fetchFromGitHub,
          }:
          prev.yaziPlugins.mkYaziPlugin {
            pname = "macos-trash.yazi";
            version = "unstable-2026-06-22";

            installPhase = ''
              runHook preInstall

              cp -r . $out

              runHook postInstall
            '';

            src = fetchFromGitHub {
              owner = "walavave";
              repo = "macos-trash.yazi";
              rev = "130e6dd80d544b97016c877251dc7d51a0aac5a0";
              hash = "sha256-A3nUll80LWWZcbX+2GjGUQA5lMbQPBwYKfOT+Sir24k=";
            };

            meta = {
              description = "macOS trash plugin for Yazi";
              homepage = "https://github.com/walavave/macos-trash.yazi";
              license = prev.lib.licenses.mit;
            };
          }
        ) { };
      };
    };
  };
  inputs = {
    nix-gleam.url = "github:arnarg/nix-gleam/347afd30f4d2701d16913f285f430731343cd96f";
  };
}
