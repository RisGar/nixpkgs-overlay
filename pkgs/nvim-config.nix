{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "72747d6fe7e34ae2b3b9c804d5de2b81d8c4fd36";
    hash = "sha256-84L6OHPyt3deXPTI1A9lwto3TeLuzJ3DixENfRRuad0=";
  };
in
(callPackage "${src}/default.nix" { }).overrideAttrs (old: {
  pname = "nvim-config";
  inherit src;
})
