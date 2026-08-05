{
  description = "Overlay for nixpkgs";
  outputs =
    {
      self,
      nixpkgs,
      nix-gleam,
      nixpkgs-logseq,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      homeManagerModules.default = ./modules/jellyfin-mpv-shim.nix;
      overlays.default = final: prev: {
        jellyfin-mpv-shim = prev.callPackage ./pkgs/jellyfin-mpv-shim { };
        thaw = prev.callPackage ./pkgs/thaw.nix { };
        mole-mac = prev.callPackage ./pkgs/mole-mac.nix { };
        dragterm = prev.callPackage ./pkgs/dragterm.nix { };
        walavave-trash-cli = prev.callPackage ./pkgs/walavave-trash-cli.nix { };
        drucktool-utils = prev.callPackage ./pkgs/drucktool-utils.nix { };
        create-thesis = prev.lib.addMetaAttrs { mainProgram = "create-thesis"; } final.drucktool-utils;
        autonup = prev.lib.addMetaAttrs { mainProgram = "autonup"; } final.drucktool-utils;
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
            pkgs' = import nixpkgs-logseq { system = prev.stdenv.hostPlatform.system; }; # TODO: wait for https://github.com/NixOS/nixpkgs/pull/516682
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

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
            config.allowUnfree = true;
          };
          # Dynamically extract all attributes defined in our overlay
          pkgs' = self.overlays.default pkgs pkgs;
        in
        pkgs.lib.filterAttrs (
          name: pkg: pkgs.lib.isDerivation pkg && pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform pkg
        ) pkgs'
      );
    };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-gleam.url = "github:arnarg/nix-gleam/main";
    nixpkgs-logseq.url = "github:NixOS/nixpkgs/ec0c722e017dfccbb2f66a8aafbe003320266d33";
  };
}
