{ stdenvNoCC
, lib
, makeWrapper
, parsec-bin, appdata, src, version
}: stdenvNoCC.mkDerivation {
  pname = "parsec";
  inherit src version appdata;
  inherit (parsec-bin) meta runtimeDependenciesPath prepareParsec;

  nativeBuildInputs = [ makeWrapper ];

  parsecd = parsec-bin;
  inherit (appdata) so_name;

  unpackPhase = ":";

  installPhase = ''
    runHook preInstall

    install -d $out/{bin,share}
    if [[ -e $parsecd/bin/.parsecd-wrapped ]]; then
      cp $parsecd/bin/.parsecd-wrapped $out/bin/parsecd
    else
      cp $parsecd/bin/parsecd $out/bin/parsecd
    fi
    cp -Lr --no-preserve=mode $parsecd/share $out/

    ls -l $out/share/parsec/
    rm $out/share/parsec/skel/parsecd-*.so
    ln -s $src $out/share/parsec/skel/$so_name
    ln -sf $appdata $out/share/parsec/skel/appdata.json

    wrapProgram $out/bin/parsecd \
      --prefix LD_LIBRARY_PATH : "$runtimeDependenciesPath" \
      --run "$prepareParsec"

    runHook postInstall
  '';
}
