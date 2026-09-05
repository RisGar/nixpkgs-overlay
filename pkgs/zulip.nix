{
  stdenv,
  lib,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm_11,
  pnpmConfigHook,
  python3,
  electron_42,
  makeDesktopItem,
  makeBinaryWrapper,
  copyDesktopItems,
  darwin,
}:

let
  electron = electron_42;
  pnpm = pnpm_11;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zulip";
  version = "5.12.4";

  src = fetchFromGitHub {
    owner = "zulip";
    repo = "zulip-desktop";
    tag = "v${finalAttrs.version}";
    hash = "sha256-0TQKQfjfA1Nn/xvtHF0t6i+whLkyu1kVwuZ62Z0AZgk=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-D9Ge0Ao1fnVA1hk+K1ScZ3iCnl1+iqUtZSG5ACO2H2M=";
  };

  # On Linux, Electron is the source-built `electron` package; on Darwin,
  # nixpkgs provides the official prebuilt Electron app (`electron_42-bin`).
  # Point Electron's tooling at the Nix-provided distribution so nothing is
  # downloaded during the build (same approach as podman-desktop).
  env = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    ELECTRON_OVERRIDE_DIST_PATH = electron.dist;
  };

  nativeBuildInputs =
    [
      nodejs
      pnpm
      pnpmConfigHook
      makeBinaryWrapper
      python3
    ]
    ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
      copyDesktopItems
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      # electron-builder leaves the assembled .app unsigned (`identity=null`
      # below); ad-hoc sign the binaries so the app runs on Apple Silicon.
      darwin.autoSignDarwinBinariesHook
    ];

  buildPhase =
    ''
      runHook preBuild

      pnpm exec electron-vite build
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      # electron-builder needs a writable copy of the Electron distribution
      # to assemble the .app bundle.
      cp -r ${electron.dist} electron-dist
      chmod -R u+w electron-dist
    ''
    + (
      if stdenv.hostPlatform.isDarwin then
        ''
          npm_package_config_node_gyp_nodedir=${electron.headers} \
            pnpm exec electron-builder --dir \
            -c.mac.identity=null \
            -c.electronDist=electron-dist \
            -c.electronVersion=${electron.version}
        ''
      else
        ''
          npm_package_config_node_gyp_nodedir=${electron.headers} \
            pnpm exec electron-builder --dir \
            -c.electronDist=${electron.dist} \
            -c.electronVersion=${electron.version}
        ''
    )
    + ''
      runHook postBuild
    '';

  installPhase =
    ''
      runHook preInstall
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      mkdir -p "$out/Applications"
      mv dist/mac*/Zulip.app "$out/Applications"
    ''
    + lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
      mkdir -p "$out/share/lib/zulip"
      cp -r dist/*-unpacked/resources/app.asar* "$out/share/lib/zulip/"

      install -m 444 -D app/resources/zulip.png $out/share/icons/hicolor/512x512/apps/zulip.png

      makeBinaryWrapper '${lib.getExe electron}' "$out/bin/zulip" \
        --add-flags "$out/share/lib/zulip/app.asar" \
        --inherit-argv0
    ''
    + ''
      runHook postInstall
    '';

  # .desktop entries are Linux-only; on Darwin the .app bundle is installed
  # into $out/Applications instead.
  desktopItems = lib.optionals (!stdenv.hostPlatform.isDarwin) [
    (makeDesktopItem {
      name = "zulip";
      exec = "zulip %U";
      icon = "zulip";
      desktopName = "Zulip";
      comment = "Zulip Desktop Client for Linux";
      categories = [
        "Chat"
        "Network"
        "InstantMessaging"
      ];
      startupWMClass = "Zulip";
      terminal = false;
    })
  ];

  meta = {
    description = "Desktop client for Zulip Chat";
    homepage = "https://zulip.com";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ andersk ];
    # Match Electron's supported platforms (Linux + Apple Silicon macOS).
    # On Darwin `electron_42` is the prebuilt electron_42-bin, which nixpkgs
    # only provides for aarch64-darwin.
    inherit (electron.meta) platforms;
    mainProgram = "zulip";
  };
})
