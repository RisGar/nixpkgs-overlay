{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "nlintn";
    repo = "nixln-edit";
    rev = "42c5063cde88cac90f87e357700c086c4d611fa4";
    sha256 = "04jqi134la22bbcg17cvswfj3hpi3j4s7bik80d1m0g9s15z3llv";
  };
in
callPackage "${src}/default.nix" { }
