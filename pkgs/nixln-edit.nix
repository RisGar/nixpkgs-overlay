{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "nlintn";
    repo = "nixln-edit";
    rev = "42c5063cde88cac90f87e357700c086c4d611fa4";
    hash = "sha256-m9LxS9DpgRoaQDOuo4kc8cIhHdebnfDYWkIoSkaIWBI=";
  };
in
callPackage "${src}/default.nix" { }
