{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
  stdenvNoCC,
}:

let
  version = "0.25.12";
  assets = {
    aarch64-darwin = {
      name = "markdown-oxide-v${version}-aarch64-apple-darwin";
      hash = "sha256-KnlTKpaezHP5EZYXdNs7VEizNzhh1/D4zKoqfk/QHpk=";
    };
    x86_64-linux = {
      name = "markdown-oxide-v${version}-x86_64-unknown-linux-gnu";
      hash = "sha256-fYUgRoDv0uWiuy1LsTmnGsTE34mth8TrPYd4PRvE9U4=";
    };
  };
  system = stdenvNoCC.hostPlatform.system;
  asset = assets.${system} or (throw "markdown-oxide-bin does not support ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "markdown-oxide-bin";
  inherit version;

  src = fetchurl {
    url = "https://github.com/Feel-ix-343/markdown-oxide/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };

  dontUnpack = true;
  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/markdown-oxide"
    runHook postInstall
  '';

  meta = {
    description = "PKM Markdown language server";
    homepage = "https://github.com/Feel-ix-343/markdown-oxide";
    license = lib.licenses.asl20;
    mainProgram = "markdown-oxide";
    platforms = builtins.attrNames assets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
