{
  fetchFromGitHub,
  lib,
  stdenv,
  swift,
  swiftpm,
  cacert,
  git,
  ...
}:
let
  version = "1.5.0";
  src = fetchFromGitHub {
    owner = "schappim";
    repo = "ekctl";
    tag = "v${version}";
    hash = "sha256-xY0gSekxdGlfK/NcxTzWfVdx1QdsRYnF1Z0UU4FkSOU=";
  };
  swiftDeps = stdenv.mkDerivation {
    pname = "ekctl-deps";
    inherit version src;

    nativeBuildInputs = [
      swift
      swiftpm
      cacert
      git
    ];

    buildPhase = ''
      export HOME=$(mktemp -d)
      swift package resolve
    '';

    installPhase = ''
      mkdir -p $out
      cp -r .build/repositories $out/
      cp -r .build/checkouts $out/
      cp .build/workspace-state.json $out/

      # Remove git and scripts that might cause store path references
      find $out -name ".git" -type d -prune -exec rm -rf {} +
      find $out -name "*.sh" -type f -delete
      find $out -type f -exec sed -i 's|/nix/store/[^/]*||g' {} + || true
    '';

    dontPatchShebangs = true;
    dontFixup = true;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-zctFU5w9gBdsJLo6t0oAykva/WQDbKoM58IcLBE9Gzs=";
  };
in
stdenv.mkDerivation {
  pname = "ekctl";
  inherit version src;

  nativeBuildInputs = [
    swift
    swiftpm
  ];

  preBuild = ''
    mkdir -p .build
    cp -r ${swiftDeps}/* .build/
    chmod -R +w .build
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp "$(swiftpmBinPath)/ekctl" $out/bin/

    runHook postInstall
  '';

  meta = {
    description = "A native macOS CLI tool for managing Calendar events and Reminders via EventKit with JSON output";
    homepage = "https://github.com/schappim/ekctl";
    maintainers = [ ];
    platforms = lib.platforms.darwin;
  };
}
