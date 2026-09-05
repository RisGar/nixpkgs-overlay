{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "devonthink";
  version = "3.9.16";

  src = fetchzip {
    url = "https://download.devontechnologies.com/download/devonthink/3.9.16/DEVONthink_3.app.zip";
    hash = "sha256-CInDHwUbC75d7h1PBte3meqYPJ75Q9ZXm0soC5dFneA=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -r *.app "$out/Applications"

    runHook postInstall
  '';

  meta = {
    description = "Document and information manager for macOS";
    homepage = "https://www.devontechnologies.com/apps/devonthink";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
