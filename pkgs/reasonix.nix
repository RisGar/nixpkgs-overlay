{
  callPackage,
  fetchFromGitHub,
  lib,
}:

let
  src = fetchFromGitHub {
    owner = "numtide";
    repo = "llm-agents.nix";
    rev = "bffbfec7ef13d6f4b925ad20046133d6b49ac9e0";
    hash = "sha256-zUTsGy8oiUo4qaeDR5qZ1y+nSUyp+3ZBceW9slrnbPc=";
  };
in
callPackage "${src}/packages/reasonix/package.nix" {
  flake = {
    lib = lib.extend (
      _final: prev: {
        maintainers = prev.maintainers // {
          arch-fan = {
            github = "arch-fan";
            githubId = 55891793;
            name = "arch-fan";
          };
        };
      }
    );
  };

  versionCheckHomeHook = callPackage "${src}/packages/versionCheckHomeHook/package.nix" { };
}
