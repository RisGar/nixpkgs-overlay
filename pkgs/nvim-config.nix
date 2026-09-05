{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "391e18631c114ed6cec12bccbf3bd53126bf1f9d";
    hash = "sha256-cthJdac0gJPArMGVRtOubAbI9+fsrbSBC1aASo0IgEw=";
  };
in
(callPackage "${src}/default.nix" { }).overrideAttrs (old: {
  pname = "nvim-config";
  inherit src;
})
