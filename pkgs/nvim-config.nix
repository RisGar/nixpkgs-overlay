{
  callPackage,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "RisGar";
    repo = "nvim-config";
    rev = "8763fa4800dd3f41807595b07475fd09363e1438";
    hash = "sha256-N6ct0yL3NITssdrd6LtjzOjhZTwhL//PwtSqrdzo1OM=";
  };
in
(callPackage "${src}/default.nix" { }).overrideAttrs (old: {
  pname = "nvim-config";
  inherit src;
})
