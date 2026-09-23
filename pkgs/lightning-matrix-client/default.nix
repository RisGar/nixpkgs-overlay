{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  unzip,
}:

# Upstream's own macOS build, not a nix build of the source tree: the release
# asset is a self-contained .app (Qt, GStreamer and every other library live in
# Contents/Frameworks and Contents/PlugIns, and Contents/Resources/qt.conf
# points the Qt plugin paths at them), so nix only has to unpack and install it.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lightning-matrix-client";
  version = "0.9.9";

  # The asset name carries the release's short commit next to the version
  # (Lightning-0.9.8-<short commit>-macos-arm64.zip), so it is pinned whole
  # rather than assembled from `version` alone; update.py resolves the new
  # release's asset name from the release's own asset list. Only
  # aarch64-darwin is published, which is also what meta.platforms allows
  # below.
  src = fetchurl {
    url = "https://github.com/Mizerd/lightning/releases/download/v${finalAttrs.version}/Lightning-${finalAttrs.version}-54d1bdb-macos-arm64.zip";
    hash = "sha256-yk7sy6woKrXtEkbQD8khRp0F1UIxgOg57IVG4o+aq3A=";
  };

  # The zip holds a bare Lightning.app at its root, so nothing may be cd'd into.
  sourceRoot = ".";

  nativeBuildInputs = [
    unzip
    makeWrapper
  ];

  # The bundle is copied verbatim. It is ad-hoc signed and its
  # Contents/_CodeSignature seals the ~1900 bundle resources, so every rewrite
  # this package used to do -- macdeployqt, a load-command fixup pass, or the
  # wrapQtAppsHook wrapper taking the executable's place -- would invalidate the
  # signature and get the app killed on launch. None of them are needed either:
  # the binary reaches its libraries through @executable_path/../Frameworks and
  # qt.conf, all of which the bundle carries.
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Lightning.app "$out/Applications/Lightning.app"

    runHook postInstall
  '';

  # Deliberately a wrapper *next to* the bundle instead of a rewrite inside it:
  # the bundle stays untouched and signing-valid, while nix run (mainProgram),
  # and anything pointing at the old $out/bin/lightning-matrix, keep working.
  # makeWrapper execs the binary in place, so NSBundle/NSApplication still see
  # the enclosing .app and its icon and resources.
  postInstall = ''
    mkdir -p "$out/bin"
    makeWrapper "$out/Applications/Lightning.app/Contents/MacOS/Lightning" \
      "$out/bin/lightning-matrix"
  '';

  meta = {
    homepage = "https://www.lightning-matrix.org";
    description = "Native Qt 6/QML Matrix desktop client (C++20 + official Rust Matrix SDK)";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "lightning-matrix";
  };
})
