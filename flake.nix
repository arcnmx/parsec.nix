{
  inputs = {
    parsec-linux-appdata = {
      url = "https://builds.parsecgaming.com/channel/release/appdata/linux/latest";
      flake = false;
    };
    parsec-linux-package = {
      url = "https://builds.parsecgaming.com/package/parsec-linux.deb";
      flake = false;
    };
    parsec-rpi-appdata = {
      url = "https://builds.parsecgaming.com/channel/release/appdata/rpi/latest";
      flake = false;
    };
    parsec-rpi-package = {
      url = "https://builds.parsecgaming.com/package/parsec-rpi.deb";
      flake = false;
    };
    nixpkgs = { };
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    inherit (nixpkgs) lib;
    platforms = {
      rpi = {
        system = "armv6l-linux";
      };
      linux = {
        system = "x86_64-linux";
      };
    };
    mapPlatformsLib = id: platform: rec {
      appdata = builtins.fromJSON (builtins.readFile inputs."parsec-${id}-appdata") // {
        outPath = inputs."parsec-${id}-appdata";
      };
      binary = builtins.fetchurl {
        url = "https://builds.parsecgaming.com/channel/release/binary/${id}/gz/${appdata.so_name}";
        sha256 = appdata.hash;
      };
      version = let
        version = self.lib.parseSoName appdata.so_name;
      in version // {
        __toString = _: "${version.major}-${version.minor}";
      };
      package = inputs."parsec-${id}-package" // {
        version = {
          "sha256-SihawQ7u031f3PiquJPsFDwf64tN1WYVGY22XZ3ChnA=" = "150-28";
          "sha256-WCkrFf3YwHFsVnSXbi/6zM1OLjn/BpoLvFeW4bP9IUw=" = "150-22";
        }.${package.narHash or ""} or (builtins.trace "WARN: unrecognized parsecd package version" "0");
      };
    };
    mapPackages = f: id: platform: let
      inherit (platform) system;
      res = f {
        inherit id system;
        parsec = self.lib.forPlatform.${id};
        pkgs = nixpkgs.legacyPackages.${system};
        packages = self.packages.${system};
        legacyPackages = self.legacyPackages.${system}.parsec;
      };
    in lib.nameValuePair system res;
    mapPlatforms = f: lib.mapAttrs' (mapPackages f) platforms;
    matchSoName = builtins.match ''(parsecd)-([0-9]*)-([^.]*)\.so'';
  in {
    lib = {
      forPlatform = lib.mapAttrs mapPlatformsLib platforms;
      parseSoName = so_name: let
        matches = matchSoName so_name;
      in {
        name = lib.elemAt matches 0;
        major = lib.elemAt matches 1;
        minor = lib.elemAt matches 2;
      };
    };
    legacyPackages = mapPlatforms ({ id, parsec, pkgs, packages, legacyPackages, ... }: {
      parsec = lib.recurseIntoAttrs {
        inherit (packages.default) name pname version type outPath drvPath outputs;

        package = pkgs.callPackage ./parsec-src.nix {
          platformId = id;
          src = parsec.package;
          inherit (parsec.package) version;
        };
        parsecd = pkgs.callPackage ./parsec-bin.nix rec {
          src = legacyPackages.package;
          version = src.version;
        };
        parsec = pkgs.callPackage ./parsec.nix {
          parsec-bin = legacyPackages.parsecd;
          inherit (parsec) appdata;
          src = parsec.binary;
          version = toString parsec.version;
        };
      };
    });
    packages = mapPlatforms ({ id, parsec, pkgs, packages, legacyPackages, ... }: {
      default = packages.parsec;
      parsecd = pkgs.parsec-bin or legacyPackages.parsecd;
      parsec = legacyPackages.parsec.override {
        parsec-bin = packages.parsecd;
      };
    });
  };
}
