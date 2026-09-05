{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "3201a2bf3bbe31cfd4a0a16b825515a25732e7c8";
    hash = "sha256-KlVIYy58L/ChyKv2HFZEb2/OWK4K/U5BvaIX/nEtaSI=";
  };
in
(callPackage "${src}/default.nix" { }).overrideAttrs (old: {
  pname = "nvim-config";
  inherit src;
})
