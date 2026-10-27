{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:

# omp-agent-setup selects this version in `.bun-version`. nixpkgs' `bun` stays
# for the packages that build with it, so this package has its own name.
let
  version = "1.4.4";
  assets = {
    aarch64-darwin = {
      name = "bun-darwin-aarch64";
      hash = "sha256-wkDX8My5DCY6hJ/NsJt+5iYw2SE0jtaq/ahrnVd7xRA=";
    };
  };
  system = stdenvNoCC.hostPlatform.system;
  asset = assets.${system} or (throw "bun-bin does not support ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "bun-bin";
  inherit version;

  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/${asset.name}.zip";
    inherit (asset) hash;
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = asset.name;

  installPhase = ''
    runHook preInstall
    install -Dm755 bun "$out/bin/bun"
    runHook postInstall
  '';

  meta = {
    description = "Bun JavaScript runtime at the version omp-agent-setup selects";
    homepage = "https://bun.sh";
    license = lib.licenses.mit;
    mainProgram = "bun";
    platforms = builtins.attrNames assets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
