{
  lib,
  stdenvNoCC,
  undmg,
  fetchurl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "vorssaint";
  version = "3.3.5";

  src = fetchurl {
    url = "https://github.com/vorssaint/vorssaint-utils/releases/download/v${finalAttrs.version}/Vorssaint-${finalAttrs.version}.dmg";
    hash = "sha256-0MQggfva7yHGI5/sZUyIdZZU437NUMk7dHNryt/skpQ=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ undmg ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -r *.app "$out/Applications"

    runHook postInstall
  '';

  meta = {
    description = "Free and open-source macOS menu bar toolkit";
    homepage = "https://vorssaint.com/";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
