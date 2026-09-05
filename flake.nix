{
  description = "Overlay for nixpkgs";
  outputs =
    {
      self,
      nixpkgs,
      nix-gleam,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      homeManagerModules.default = ./modules/jellyfin-mpv-shim.nix;
      overlays.default = final: prev: {
        jellyfin-mpv-shim = prev.callPackage ./pkgs/jellyfin-mpv-shim { };
        lightning-matrix-client = prev.callPackage ./pkgs/lightning-matrix-client { };
        logseq = prev.callPackage ./pkgs/logseq_2 { }; # TODO: wait for https://github.com/NixOS/nixpkgs/pull/516682 to be merged
        thaw = prev.callPackage ./pkgs/thaw.nix { };
        mole-mac = prev.callPackage ./pkgs/mole-mac.nix { };
        dragterm = prev.callPackage ./pkgs/dragterm.nix { };
        drucktool-utils = prev.callPackage ./pkgs/drucktool-utils.nix { };
        create-thesis = prev.lib.addMetaAttrs { mainProgram = "create-thesis"; } final.drucktool-utils;
        autonup = prev.lib.addMetaAttrs { mainProgram = "autonup"; } final.drucktool-utils;
        nvim = prev.callPackage ./pkgs/nvim-config.nix { };
        nixln-edit = prev.callPackage ./pkgs/nixln-edit.nix { };
        print-cli-rs = prev.callPackage ./pkgs/print-cli-rs.nix { };
        nerdfont-cheatsheet = prev.callPackage ./pkgs/nerdfont-cheatsheet.nix { nix-gleam = nix-gleam; };
        vorssaint = prev.callPackage ./pkgs/vorssaint.nix { };
        devonthink = prev.callPackage ./pkgs/devonthink.nix { };
        reasonix = prev.callPackage ./pkgs/reasonix.nix { };
        # TODO: detexify-next

        signal-desktop = prev.signal-desktop.override {
          withAppleEmojis = true;
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
    nix-gleam.inputs.nixpkgs.follows = "nixpkgs";
  };
}
