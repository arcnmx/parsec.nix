{ stdenvNoCC
, dpkg
, src, version, platformId
}:

stdenvNoCC.mkDerivation {
  pname = "parsec-${platformId}";
  inherit src version;

  nativeBuildInputs = [ dpkg ];

  buildCommand = ''
    dpkg-deb -x $src .

    mkdir $out
    mv usr $out/
  '';
}
