{ callPackage, fetchFromGitHub }:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "print-cli-rs";
    rev = "05c0628358ba2d1806f65999780b8fd931775a08";
    hash = "sha256-CUTs/5SxcOHQzo4rablu6kIAzp8HriBKEyOwOh8Tz44=";
  };
in
callPackage "${src}/default.nix" { }
