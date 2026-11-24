{
  callPackage,
  fetchFromGitHub,
  makeRustPlatform,
  rust-bin,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "drs150-bridge";
    rev = "5d74b3bdb504ee4204d7ecdc5e0d99d8a35f8873";
    hash = "sha256-vp4BiWE7aWdZ38PeVZ90kJeG6DQVCn/yLqzF62flZO8=";
  };

  rust = rust-bin.stable.latest.default.override {
    targets = [ "x86_64-apple-darwin" ];
  };
in
(callPackage "${src}/default.nix" {
  rustPlatform = makeRustPlatform {
    cargo = rust;
    rustc = rust;
  };
}).default.overrideAttrs
  (_: {
    inherit src;
  })
