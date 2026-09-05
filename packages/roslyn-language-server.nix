{
  autoPatchelfHook,
  dotnetCorePackages,
  fetchurl,
  lib,
  makeWrapper,
  stdenv,
  stdenvNoCC,
  unzip,
}:

let
  version = "5.12.0-1.26426.8";
  assets = {
    aarch64-darwin = {
      package = "roslyn-language-server.osx-arm64";
      rid = "osx-arm64";
      hash = "sha256-1W4nJ4hZmgiUQofhcJLQlRoy6FzW99XvLMHkQTMfpTE=";
    };
    x86_64-linux = {
      package = "roslyn-language-server.linux-x64";
      rid = "linux-x64";
      hash = "sha256-UPiENfWHVkD7I0GHhhjb+uxDVKGhNO/KwK5VckdEilg=";
    };
  };
  system = stdenvNoCC.hostPlatform.system;
  asset = assets.${system} or (throw "roslyn-language-server-bin does not support ${system}");
  dotnetRuntime = dotnetCorePackages."runtime_10_0-bin";
  executable = "Microsoft.CodeAnalysis.LanguageServer";
in
stdenvNoCC.mkDerivation {
  pname = "roslyn-language-server-bin";
  inherit version;

  src = fetchurl {
    url = "https://api.nuget.org/v3-flatcontainer/${asset.package}/${version}/${asset.package}.${version}.nupkg";
    inherit (asset) hash;
  };

  dontUnpack = true;
  dontStrip = true;
  nativeBuildInputs = [
    makeWrapper
    unzip
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    payload="$TMPDIR/package/tools/net10.0/${asset.rid}"
    unzip -q "$src" -d "$TMPDIR/package"
    test -f "$payload/${executable}.dll"
    test -f "$payload/${executable}.runtimeconfig.json"

    mkdir -p "$out/lib/roslyn-language-server"
    cp -R "$payload"/. "$out/lib/roslyn-language-server/"
    makeWrapper ${lib.getExe dotnetRuntime} "$out/bin/${executable}" \
      --add-flags "$out/lib/roslyn-language-server/${executable}.dll"

    runHook postInstall
  '';

  meta = {
    description = "Roslyn language server from Microsoft's platform tool package";
    homepage = "https://github.com/dotnet/roslyn";
    license = lib.licenses.mit;
    mainProgram = executable;
    platforms = builtins.attrNames assets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
