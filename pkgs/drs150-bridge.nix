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
    rev = "929d806e1013079ac45622e334e51550a656c581";
    hash = "sha256-zPQiLDPEF313mNykAm4cbP11h9WAlJ95Yi+ZA8vgrmM=";
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
