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
    rev = "3173ea56b31b501a49c646330cd139e9dfe32d6e";
    hash = "sha256-IQkj6tD2IQygX9S0a49V13NTYzQX8TfXV2V9AiRB25I=";
  };
in
callPackage "${src}/default.nix" {
  inherit (nix-gleam.packages.${stdenv.hostPlatform.system}) buildGleamApplication;
}
