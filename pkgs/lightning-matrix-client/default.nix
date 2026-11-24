{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lightning-matrix-client";
  version = "0.10.7";

  src = fetchurl {
    url = "https://github.com/Mizerd/lightning/releases/download/v${finalAttrs.version}/Lightning-${finalAttrs.version}-33fe56b-macos-arm64.zip";
    hash = "sha256-0qXljAEwMxlRfnC4yyi9BWMWvUDHGveuVHfaMysnh7g=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    unzip
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Lightning.app "$out/Applications/Lightning.app"

    runHook postInstall
  '';

  postInstall = ''
    mkdir -p "$out/bin"
    makeWrapper "$out/Applications/Lightning.app/Contents/MacOS/Lightning" \
      "$out/bin/lightning-matrix"
  '';

  meta = {
    homepage = "https://www.lightning-matrix.org";
    description = "Native Qt 6/QML Matrix desktop client (C++20 + official Rust Matrix SDK)";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "lightning-matrix";
  };
})
