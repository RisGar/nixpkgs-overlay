{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "89aa30672ea44cde29470a4b4786e3199765aab7";
    hash = "sha256-HNvnizjuzUkXVnahXAkG1o7zZG/o/hi+CY1g5trwCdw=";
  };
in
(callPackage "${src}/default.nix" { }).overrideAttrs (old: {
  pname = "nvim-config";
  inherit src;
})
