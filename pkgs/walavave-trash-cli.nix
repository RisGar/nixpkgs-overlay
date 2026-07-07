{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "walavave-trash-cli";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "walavave";
    repo = "trash-cli";
    rev = "v${version}";
    hash = "sha256-IKoMOrlLLXfC0V58dSadrbIvaVX6zfADUs4iXLxgWZc=";
  };

  cargoHash = "sha256-aj1d3fdSbMWrEtaiXYlbGVqBbIgl052jrkTuqicU/+s=";

  meta = {
    description = "A command-line interface for managing the macOS Trash";
    homepage = "https://github.com/walavave/trash-cli";
    license = lib.licenses.mit;
    mainProgram = "trash";
  };
}
