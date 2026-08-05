{
  callPackage,
  fetchFromGitHub,
  jdk17,
  jdk21,
  jdk25,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "fda516c79a707a3ebad302782ac1a37c87a69447";
    hash = "sha256-E9DgzPk/uBKtKtHHb5PXBjGECbFF1A6l6xqG/VlBf3g=";
  };
in
callPackage "${src}/default.nix" {
  jdks = [
    jdk17
    jdk21
    jdk25
  ];
}
