{
  lib,
  stdenvNoCC,
  undmg,
  fetchurl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "vorssaint";
  version = "3.3.2";

  src = fetchurl {
    url = "https://github.com/vorssaint/vorssaint-utils/releases/download/v${finalAttrs.version}/Vorssaint-${finalAttrs.version}.dmg";
    hash = "sha256-f6+LVXU6TzTMzNZcIMLuhH2I43QVnfu5Xu3NUKpTQcs=";
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
    description = "Powerful menu bar manager for macOS";
    homepage = "https://github.com/stonerl/Thaw";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
