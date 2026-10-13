{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "e2209e37252c887fb8d8b41f26b644f65f9064f3";
    hash = "sha256-kezfeqKhmyQHzlBWcgk9jXK0ee4mWsUHkkAgPe5LoKc=";
  };
in
(callPackage "${src}/default.nix" { }).overrideAttrs (old: {
  pname = "nvim-config";
  inherit src;
})
