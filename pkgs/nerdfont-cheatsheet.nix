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
    rev = "45bf183f52e209a1476d791dc3d5c140fa3b6aa0";
    hash = "sha256-/bVL9vtdSxQ2P2VncdkHdnAS9lc4cseOxUXNPJe2PM8=";
  };
in
callPackage "${src}/default.nix" {
  inherit (nix-gleam.packages.${stdenv.hostPlatform.system}) buildGleamApplication;
}
