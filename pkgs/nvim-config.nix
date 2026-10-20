{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "a761ae51a495acf5c922b282ed1e1664ba685343";
    hash = "sha256-6w384cDH8ZZfwfIDse8+d4GJjyqqP4tkss91Gl/plMA=";
  };
in
(callPackage "${src}/default.nix" { }).overrideAttrs (old: {
  pname = "nvim-config";
  inherit src;
})
