{
  callPackage,
  fetchFromGitHub,
  stdenv,
  nix-gleam,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nerdfont_cheatsheet";
    rev = "d9c3c363b7ac4bcecd4fc2abedb88e0a9ca23f40";
    hash = "sha256-2gQsZDFvdh4UaNhYR2p4vCai10OAhegtSNopqDVjPK8=";
  };
in
callPackage "${src}/default.nix" {
  inherit (nix-gleam.packages.${stdenv.hostPlatform.system}) buildGleamApplication;
}
