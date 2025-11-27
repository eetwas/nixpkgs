{
  lib,
  buildGoModule,
  pkgs ? import <nixpkgs> { },
  stdenv,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  yarnInstallHook,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "ots-server";
  version = "1.20.0";

  src = fetchFromGitHub {
    owner = "Luzifer";
    repo = "ots";
    rev = "v${version}";
    hash = "sha256-Jw0xO937deb6ffZbrV0/mvEWrdRGn2wg6JJ/OHPxluQ=";
  };

  vendorHash = "sha256-330GVaY7cxPwLFl3tys9ao7eVY/PVSqX6M/FEXvForw=";

  ots-frontend = stdenv.mkDerivation {
    pname = "ots-server-frontend";
    inherit src meta version;
    sourceRoot = "${src.name}";

    yarnOfflineCache = fetchYarnDeps {
      yarnLock = "${src}/yarn.lock";
      hash = "sha256-1o1OMwKE514pcVnHqrBWGiMDW7c483tGd/dZVdswLUU=";
    };

    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.yarn
      yarnConfigHook
      yarnBuildHook
      yarnInstallHook
    ];

    buildPhase = ''
      export NODE_ENV=production

      yarn install --offline --production=false --frozen-lockfile
      yarn --offline node ci/build.mjs
    '';

    installPhase = ''
      cp -r frontend/ $out
    '';
  };

  ots-cli = buildGoModule {
    pname = "ots-server-cli";
    inherit src meta version;
    sourceRoot = "${src.name}/cmd/ots-cli";

    vendorHash = "sha256-lCjFAgj4TgDhANQbUzdwJW19vlcQ62TyivMDUPkEaUs=";
  };

  ots-customization = buildGoModule {
    pname = "ots-server-customization";
    inherit src meta version;
    sourceRoot = "${src.name}/pkg/customization";

    vendorHash = "sha256-0cv87+65xzIJv8Lkqkvs3lSTGqvjlu+ySqkKJpp/2I0=";
  };

  nativeBuildInputs = [
    pkgs.git
    ots-cli
    ots-frontend
    ots-customization
  ];

  prePatch = ''
    cp -r ${ots-frontend}/* ./frontend
  '';

  excludedPackages = [
    "ci/translate"
    "cmd/ots-cli"
    "pkg/client"
    "pkg/customization"
  ];

  ldflags = [
    "-s"
    "-w"
  ];

  preInstall = ''
    mkdir -p $out/bin
    cp ${ots-cli}/bin/ots-cli $out/bin
  '';

  meta = {
    description = "One-Time-Secret sharing platform with a symmetric 256bit AES encryption in the browser";
    homepage = "https://github.com/Luzifer/ots";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ eetwas ];
    mainProgram = "ots";
  };
}
