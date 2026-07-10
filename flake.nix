{
  description = "Overlay for nixpkgs";
  outputs = inputs: {
    overlays.default =
      final: prev:
      let
        system = prev.stdenv.hostPlatform.system;
      in
      {
        thaw = prev.callPackage ./pkgs/thaw.nix { };
        mole-mac = prev.callPackage ./pkgs/mole-mac.nix { };
        dragterm = prev.callPackage ./pkgs/dragterm.nix { };
        walavave-trash-cli = prev.callPackage ./pkgs/walavave-trash-cli.nix { };
        create-thesis = prev.callPackage ./pkgs/create-thesis.nix { };
        ekctl = prev.callPackage ./pkgs/ekctl.nix { };

        logseq = (
          let
            pkgs' = import (fetchTarball {
              url = "https://github.com/NixOS/nixpkgs/archive/ec0c722e017dfccbb2f66a8aafbe003320266d33.tar.gz";
              sha256 = "0jws2i94asr1yish76799gmyw51dj98n8badq3snc8prifmsd3a5";
            }) { system = prev.stdenv.hostPlatform.system; };
          in
          pkgs'.logseq
        );

        signal-desktop = prev.signal-desktop.override {
          withAppleEmojis = true;
        };

        nvim = prev.callPackage inputs.nvim-config {
          jdks = with prev; [
            jdk17
            jdk21
            jdk25
          ];
        };

        nerdfont-cheatsheet = inputs.nerdfont-cheatsheet.packages.${system}.default;
        nixln-edit = inputs.nixln-edit.packages.${system}.default;
        ocrtool-mcp = inputs.ocrtool-mcp.packages.${system}.default;
        print-cli-rs = inputs.print-cli-rs.packages.${system}.default;

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
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixln-edit = {
      url = "github:nlintn/nixln-edit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-config = {
      url = "github:RisGar/nvim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    print-cli-rs = {
      url = "github:RisGar/print-cli-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ocrtool-mcp = {
      url = "github:RisGar/ocrtool-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nerdfont-cheatsheet = {
      url = "github:RisGar/nerdfont_cheatsheet";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
