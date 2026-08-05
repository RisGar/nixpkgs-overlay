{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "f455d629e3dc5b51c3893f64d6e4c7721469ddee";
    hash = "sha256-B3DQn211m+EUTEax/xQC6f2rQW0NwC+WZfKDMy0IoSk=";
  };
in
(callPackage "${src}/default.nix" { }).overrideAttrs (old: {
  pname = "nvim-config";
  inherit src;
})
