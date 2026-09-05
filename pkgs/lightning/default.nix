{
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  ccache,
  mold,
  rustc,
  cargo,
  rustPlatform,
  qt6,
  pipewire,
  libsecret,
  glib,
  xkeyboard_config,
  gst_all_1,
  libnice,
  openssl,
  libicns,
  withBuildAccelerators ? false,
  withRustBackend ? true,
  fetchFromGitHub,
}:

let
  gst =
    with gst_all_1;
    [
      gstreamer
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
      libnice # makeSearchPathOutput falls back to .out
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      # pipewire ships libgstpipewire (pipewiresrc), which the screen share
      # captures through; without it on the plugin path the packaged client
      # cannot share a screen at all (contributor finding, 2026-09-05). It
      # lives in pipewire's own package (not gst_all_1), in .out since
      # pipewire has no lib output.
      pipewire
    ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "lightning-matrix-client";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "Mizerd";
    repo = "lightning";
    rev = "v${finalAttrs.version}";
    hash = "sha256-VEM+RauvigJETZxguuiu6C8JU/HTXYV9faA+Y4ld9vM=";
  };

  cargoRoot = "rust";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  # The lockfile must be readable at eval time (importCargoLock fetches each
  # crate from its checksum in the lock), and pure eval forbids reading it out
  # of the fetched src. Vendored from the pinned rev's rust/Cargo.lock; the
  # cargoSetupHook's postPatch phase verifies it still matches the src.
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.qttools
    qt6.wrapQtAppsHook
    rustPlatform.cargoSetupHook
  ]
  # png2icns builds the .app icon below; nixpkgs has no iconutil in the
  # sandbox (DarwinTools carries sw_vers etc. only), and png2icns is the
  # nixpkgs-standard replacement for it.
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    libicns
  ]
  ++ lib.optionals withRustBackend [
    rustc
    cargo
  ]
  ++ lib.optionals withBuildAccelerators [
    ccache
    mold
  ];
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtimageformats
    qt6.qtmultimedia
    glib
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    qt6.qtwayland
    pipewire
    xkeyboard_config
    libsecret
  ]
  ++ gst;

  cmakeFlags = [
    (lib.cmakeBool "ENABLE_RUST_SDK_BACKEND" withRustBackend)
  ]
  ++ lib.optionals stdenv.isDarwin [
    # A package that INTENDS to ship calling must fail configure rather than
    # silently ship a client that refuses every call: CMakeLists' GStreamer
    # WebRTC probe is AUTO and says only STATUS. The GuiPrivate clause of the
    # same option is an X11 concern and does not apply on Apple.
    (lib.cmakeBool "LIGHTNING_REQUIRE_WEBRTC" true)
  ]
  ++ lib.optionals withBuildAccelerators [
    (lib.cmakeFeature "CMAKE_CXX_COMPILER_LAUNCHER" "ccache")
    (lib.cmakeFeature "CMAKE_LINKER_TYPE" "MOLD")
  ];

  # cmakeFlags is word-split by nixpkgs' cmake hook, so a multi-word value
  # cannot live there; cmakeFlagsArray is the supported way to pass one.
  # matrix-sdk reaches TLS through rustls, whose platform verifier calls
  # into Security.framework. CMake links libmatrix_client_rust.a into the
  # C++ executable itself, so cargo's
  # `cargo:rustc-link-lib=framework=Security` directive is never seen and
  # the link fails with undefined _Sec* symbols unless the frameworks are
  # supplied here — the same linker inputs the production build-macos.sh
  # passes. CoreFoundation is the framework's own dependency.
  preConfigure = lib.optionalString stdenv.isDarwin ''
    cmakeFlagsArray+=(-DCMAKE_EXE_LINKER_FLAGS="-framework Security -framework CoreFoundation")
  '';

  # A .app bundle, assembled the way the production build-macos.sh does it:
  # CMake targets Linux/Windows layouts and never sets MACOSX_BUNDLE, so the
  # bundle is built here rather than by cmake --install. Unlike production,
  # macdeployqt and the load-command repair pass are NOT needed: everything
  # the app links lives at absolute store paths, and the wrapQtAppsHook
  # wrapper (copied as the bundle executable) supplies the Qt/GStreamer
  # plugin paths. Nothing is code-signed: a store bundle is never
  # quarantined, and production's ad-hoc signing only exists because
  # macdeployqt's rewrites invalidate signatures this bundle never had.
  postFixup = lib.optionalString stdenv.isDarwin ''
        app="$out/Applications/Lightning.app"
        mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
        cp "$out/bin/lightning-matrix" "$app/Contents/MacOS/Lightning"
        chmod 0755 "$app/Contents/MacOS/Lightning"

        # Icon: a real .icns from the source's hicolor PNGs. The 512@2x (1024px)
        # icon is deliberately omitted rather than upscaled, as in production.
        icon_src() { printf '%s/data/icons/hicolor/%sx%s/apps/lightning.png' "$src" "$1" "$1"; }
        png2icns "$app/Contents/Resources/Lightning.icns" \
            "$(icon_src 16)" "$(icon_src 32)" "$(icon_src 128)" "$(icon_src 256)" "$(icon_src 512)"

        # NSMicrophoneUsageDescription is REQUIRED, not decorative: the client
        # records voice messages through QMediaCaptureSession/QAudioInput, and
        # macOS terminates any process that touches the microphone without a
        # usage string. Same keys the production bundle carries.
        cat >"$app/Contents/Info.plist" <<PLIST
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleDevelopmentRegion</key><string>en</string>
        <key>CFBundleDisplayName</key><string>Lightning</string>
        <key>CFBundleExecutable</key><string>Lightning</string>
        <key>CFBundleIconFile</key><string>Lightning</string>
        <key>CFBundleIdentifier</key><string>net.smetonis.lightning</string>
        <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
        <key>CFBundleName</key><string>Lightning</string>
        <key>CFBundlePackageType</key><string>APPL</string>
        <key>CFBundleShortVersionString</key><string>${finalAttrs.version}</string>
        <key>CFBundleVersion</key><string>${finalAttrs.version}</string>
        <key>LSMinimumSystemVersion</key><string>${stdenv.hostPlatform.darwinMinVersion}</string>
        <key>LSApplicationCategoryType</key><string>public.app-category.social-networking</string>
        <key>NSHighResolutionCapable</key><true/>
        <key>NSHumanReadableCopyright</key><string>Copyright (C) 2026 Rokas Smetonis. GPL-3.0-or-later.</string>
        <key>NSMicrophoneUsageDescription</key><string>Lightning needs the microphone to record voice messages.</string>
        <key>NSCameraUsageDescription</key><string>Lightning needs the camera only if you attach a photo or video you capture.</string>
    </dict>
    </plist>
    PLIST
        printf 'APPL????' >"$app/Contents/PkgInfo"
  '';

  qtWrapperArgs = [
    "--prefix GST_PLUGIN_PATH : ${lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gst}"
  ];

  meta = {
    homepage = "https://www.lightning-matrix.org";
    description = "Native Qt 6/QML Matrix desktop client (C++20 + official Rust Matrix SDK)";
    license = lib.licenses.gpl3Plus;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "lightning-matrix";
  };
})
