{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  source = builtins.fromJSON (builtins.readFile ./source.json);
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit (source) version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${source.version}/codex-package-x86_64-unknown-linux-musl.tar.gz";
    inherit (source) hash;
  };

  dontUnpack = true;
  dontBuild = true;
  # Preserve the official package layout and its bundled executables/libraries.
  dontFixup = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    tar -xzf "$src" -C "$out"
    test -x "$out/bin/codex"
    test -x "$out/bin/codex-code-mode-host"
    test -f "$out/codex-package.json"
    test -x "$out/codex-path/rg"
    test -x "$out/codex-resources/bwrap"
    runHook postInstall
  '';

  meta = {
    description = "OpenAI Codex CLI, packaged from the official Linux release";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
