{ stdenvNoCC, stdenv
, lib
, autoPatchelfHook, makeWrapper
, fetchurl
, alsa-lib, openssl, udev
, libglvnd
, libX11, libXcursor, libXi, libXrandr
, libpulseaudio
, libva
, ffmpeg
, src, version
}:

stdenvNoCC.mkDerivation {
  pname = "parsec-bin";
  inherit src version;

  unpackPhase = ''
    runHook preUnpack

    cp -rs --no-preserve=mode $src/usr ./usr

    runHook postUnpack
  '';

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  buildInputs = [
    stdenv.cc.cc # libstdc++
    libglvnd
    libX11
  ];

  runtimeDependenciesPath = lib.makeLibraryPath [
    stdenv.cc.cc
    libglvnd
    openssl
    udev
    alsa-lib
    libpulseaudio
    libva
    ffmpeg
    libX11
    libXcursor
    libXi
    libXrandr
  ];

  prepareParsec = ''
    if [[ ! -e "$HOME/.parsec/appdata.json" ]]; then
      mkdir -p "$HOME/.parsec"
      cp --no-preserve=mode,ownership,timestamps ${placeholder "out"}/share/parsec/skel/* "$HOME/.parsec/"
    fi
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    mv usr/* $out

    rm $out/bin/parsecd
    cp $src/usr/bin/parsecd $out/bin/

    wrapProgram $out/bin/parsecd \
      --prefix LD_LIBRARY_PATH : "$runtimeDependenciesPath" \
      --run "$prepareParsec"

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://parsecgaming.com/";
    description = "Remote streaming service client";
    license = licenses.unfree;
    maintainers = with maintainers; [ arcnmx ];
    platforms = platforms.linux;
    mainProgram = "parsecd";
  };
}
