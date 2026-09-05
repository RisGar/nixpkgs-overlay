{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "ece847643b50e20de6f15453df0d611156bb71b3";
    hash = "sha256-w109Ap7pR2yK/p5nh3qDG77mR9XZn87TD5RPRB9Aqe8=";
  };
in
(callPackage "${src}/default.nix" { }).overrideAttrs (old: {
  pname = "nvim-config";
  inherit src;
})
