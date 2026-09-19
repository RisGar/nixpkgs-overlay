{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  unzip,
  electron,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "logseq";
  version = "2.0.1";

  src = fetchurl {
    url = "https://github.com/logseq/logseq/releases/download/${finalAttrs.version}/Logseq-darwin-arm64-${finalAttrs.version}.zip";
    hash = "sha256-kyfz+42KZnyk9en9q3JlLJSIIyJHFd6oLjc38I4BnB8=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    unzip
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Logseq.app "$out/Applications/Logseq.app"

    runHook postInstall
  '';

  postInstall = ''
    mkdir -p "$out/bin"
    makeWrapper "$out/Applications/Logseq.app/Contents/MacOS/Logseq" \
      "$out/bin/logseq"
  '';

  meta = {
    description = "Privacy-first, open-source platform for knowledge management and collaboration";
    homepage = "https://github.com/logseq/logseq";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ tomasajt ];
    mainProgram = "logseq-app";
    platforms = electron.meta.platforms;
  };
})
