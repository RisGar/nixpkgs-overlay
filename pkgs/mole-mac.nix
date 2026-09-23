{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "mole-mac";
  version = "1.55.0";

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "Mole";
    # Mole's tags are capital-V ("V1.54.0"); the lowercase prefix here produced
    # "vV1.54.0", which the archive URL does not resolve at all.
    rev = "V${finalAttrs.version}";
    hash = "sha256-Myl8ZtLYk2Dn0wHj8sl6SVVjmswcBzZ4WjjU/dJAdWE=";
  };

  vendorHash = "sha256-iGwtKV6mJfSgZ5rMB5ASXzdKTPBy9RqoysM4JRh0dts=";

  subPackages = [
    "cmd/analyze"
    "cmd/status"
  ];

  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    libexec="$out/libexec"
    mkdir -p "$libexec"
    cp -r bin lib "$libexec/"

    install -m755 mole "$out/bin/mole"
    ln -s "$out/bin/mole" "$out/bin/mo"

    install -m755 "$out/bin/analyze" "$libexec/bin/analyze-go"
    install -m755 "$out/bin/status" "$libexec/bin/status-go"
    rm -f "$out/bin/analyze" "$out/bin/status"

    substituteInPlace "$out/bin/mole" \
      --replace-fail 'SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"' "SCRIPT_DIR=\"$out/libexec\""
  '';

  doCheck = false;

  meta = {
    description = "Deep clean and optimize your Mac";
    homepage = "https://github.com/tw93/Mole";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "mo";
  };
})
