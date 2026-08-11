{
  lib,
  python3Packages,
  texlive,
  pdftk,
  ghostscript,
  fetchFromGitLab,
}:

let
  tex = texlive.withPackages (ps: with ps; [
    scheme-basic
    latexmk
    geometry
    pgf
    pdfjam
    pdfbook2
  ]);
in
python3Packages.buildPythonApplication rec {
  pname = "drucktool-utils";
  version = "1.0.0";
  format = "setuptools";

  src = builtins.fetchGit {
    url = "https://git.fs.tum.de/drucktool/drucktool-utils.git";
    rev = "062f612e3ecb1aafe59899aaca779acf6b07abee";
  };

  postUnpack = ''
    sourceRoot=$sourceRoot/source
  '';

  postPatch = ''
    sed -i 's/packages = find_packages()/scripts=["create-thesis", "autonup"]/g' setup.py
  '';

  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        pdftk
        ghostscript
        tex
      ]
    }"
  ];

  meta = {
    description = "Scripts for formatting theses";
    homepage = "https://git.fs.tum.de/drucktool/create-thesis";
    mainProgram = "drucktool-utils";
  };
}
