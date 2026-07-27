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
    rev = "67d87735a05f5c6f1397e0115a0c1538d4761a84";
    hash = "sha256-LVR4wMAjDL8Lh3Snl3pnn3Cw9E33zj1/1gZY7fCyJCM=";
  };
in
callPackage "${src}/default.nix" {
  jdks = [
    jdk17
    jdk21
    jdk25
  ];
}
