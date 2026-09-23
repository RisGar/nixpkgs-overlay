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

  # Upstream's entry script derives SCRIPT_DIR from the path it was invoked as,
  # so lib/ has to sit next to it. Its install.sh bridges that gap by rewriting
  # the SCRIPT_DIR line, in a different shape every few releases, so keep the
  # upstream checkout layout instead (mole, bin/ and lib/ side by side, as in
  # the repo root) and let the $out/bin symlinks resolve into it.
  postInstall = ''
    libexec="$out/libexec"
    mkdir -p "$libexec"

    # Inputs from the unpacked source, which stays intact for any later phase.
    cp -r bin lib "$libexec/"
    install -m755 mole "$libexec/mole"

    # buildGoModule installs these as $out/bin/{analyze,status}, but bin/*.sh
    # look for $SCRIPT_DIR/{analyze,status}-go: relocate them within $out, which
    # also keeps the bare names off the user's PATH.
    mv "$out/bin/analyze" "$libexec/bin/analyze-go"
    mv "$out/bin/status" "$libexec/bin/status-go"

    # Resolving these lands on the entry script next to lib/.
    ln -s "$libexec/mole" "$out/bin/mole"
    ln -s "$libexec/mole" "$out/bin/mo"

    # Fails the build, not the user, if the entrypoints ever stop resolving
    # their libraries on their own.
    [[ "$("$out/bin/mo" --version 2>&1)" == *"Mole version $version"* ]]
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
