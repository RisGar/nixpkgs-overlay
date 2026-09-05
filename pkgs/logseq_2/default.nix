{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  unzip,
  electron,
}:

# Upstream's own macOS build, not a nix build of the source tree: the release
# asset is a self-contained .app (Qt, GStreamer and every other library live in
# Contents/Frameworks and Contents/PlugIns, and Contents/Resources/qt.conf
# points the Qt plugin paths at them), so nix only has to unpack and install it.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "logseq";
  version = "2.0.1";

  # The asset name carries the release's short commit next to the version
  # (Lightning-0.9.8-<short commit>-macos-arm64.zip), so it is pinned whole
  # rather than assembled from `version` alone; update.py resolves the new
  # release's asset name from the release's own asset list. Only
  # aarch64-darwin is published, which is also what meta.platforms allows
  # below.
  src = fetchurl {
    url = "https://github.com/logseq/logseq/releases/download/${finalAttrs.version}/Logseq-darwin-arm64-${finalAttrs.version}.zip";
    hash = "sha256-kyfz+42KZnyk9en9q3JlLJSIIyJHFd6oLjc38I4BnB8=";
  };

  # The zip holds a bare Lightning.app at its root, so nothing may be cd'd into.
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
