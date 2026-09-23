{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "05537c6ea63a149e6fadb24f4364989bc8c2f3d5";
    hash = "sha256-Xr4ZbKORS5s6CbGKIEfoLpRKHw57nCWugZxcPYUYTMY=";
  };
in
(callPackage "${src}/default.nix" { }).overrideAttrs (old: {
  pname = "nvim-config";
  inherit src;
})
