{
  lib,
  python3Packages,
  texlive,
  pdftk,
  ghostscript,
}:

let
  tex = texlive.combine {
    inherit (texlive)
      scheme-basic
      latexmk
      geometry
      pgf
      pdfjam
      pdfbook2
      ;
  };
in
python3Packages.buildPythonApplication {
  pname = "create-thesis";
  version = "1.1.0";
  format = "setuptools";

  src = fetchGit {
    url = "https://git.fs.tum.de/drucktool/create-thesis.git";
    rev = "f07bea6e0484c11379fd1b5c4be0bc490e5776c8";
    ref = "refs/tags/v1.1.0";
  };

  # The Python setup files are in the 'source' subdirectory
  postUnpack = ''
    sourceRoot=$sourceRoot/source
  '';

  postPatch = ''
    sed -i 's/packages = find_packages()/scripts=["create-thesis"]/g' setup.py
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
    description = "Script for formatting theses";
    homepage = "https://git.fs.tum.de/drucktool/create-thesis";
    mainProgram = "create-thesis";
  };
}
