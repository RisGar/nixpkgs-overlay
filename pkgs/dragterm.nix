{
  apple-sdk_14,
  fetchFromGitHub,
  lib,
  stdenv,
  lld,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dragterm";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "Wevah";
    repo = "dragterm";
    rev = "d2989069ed13b69247e22b5a97cf4600784eb526";
    hash = "sha256-ETIfD6j5VhNVCs3Wo6tutnHULzNMO4qgqqX6blTfxBA=";
  };

  nativeBuildInputs = [ lld ];
  buildInputs = [
    apple-sdk_14
  ];

  buildPhase = ''
    # Process Info.plist to replace placeholders
    sed -e 's/$(PRODUCT_BUNDLE_IDENTIFIER)/org.derailer.dragterm/g' \
        -e 's/$(CURRENT_PROJECT_VERSION)/26/g' \
        -e 's/$(MACOSX_DEPLOYMENT_TARGET)/10.13/g' \
        dragterm/Info.plist > Info.plist

    clang -framework Cocoa -I dragterm \
        -fuse-ld=lld \
        -Wl,-sectcreate,__TEXT,__info_plist,Info.plist \
        dragterm/main.m dragterm/DTDraggingSourceView.m \
        -o drag
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp drag $out/bin/drag
  '';

  meta = {
    description = "Initiate file drags from the terminal";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    maintainers = [ ];
  };
})
