{
  stdenv,
  swift,
  swiftpm,
  fetchFromGitHub,
  lib,
  ...
}:
stdenv.mkDerivation rec {
  pname = "ocrtool-mcp";
  version = "1.0.6";

  src = fetchFromGitHub {
    owner = "ihugang";
    repo = "ocrtool-mcp";
    rev = "v${version}";
    hash = "sha256-z2CweDQK0cCyZNTZ1YZvGonhMMWNcgcpvM/NTlgE3k8=";
  };

  nativeBuildInputs = [
    swift
    swiftpm
  ];

  buildPhase = ''
    swift build -c release --disable-sandbox
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp .build/release/ocrtool-mcp $out/bin/
  '';

  meta = {
    description = "macOS native OCR tool implementing Model Context Protocol";
    homepage = "https://github.com/ihugang/ocrtool-mcp";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "ocrtool-mcp";
  };
}
