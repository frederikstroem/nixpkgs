{
  lib,
  stdenv,
  nix-update-script,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  installShellFiles,
  zstd,
  libsoup_3,
  makeWrapper,
  mono,
  wrapWithMono ? true,
  openssl,
  darwin,
}:

rustPlatform.buildRustPackage rec {
  pname = "owmods-cli";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "ow-mods";
    repo = "ow-mod-man";
    rev = "cli_v${version}";
    hash = "sha256-rTANG+yHE8YfWYUyELoKgj4El+1ZW6vI9NkgADD40pw=";
  };

  cargoHash = "sha256-qiimnkUDiFoz/68GYi0QTuYYBjowC01c3GSxUIMjNT4=";

  nativeBuildInputs = [
    pkg-config
    installShellFiles
  ] ++ lib.optional wrapWithMono makeWrapper;

  buildInputs =
    [
      zstd
      libsoup_3
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      openssl
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
    ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  buildAndTestSubdir = "owmods_cli";

  postInstall =
    ''
      cargo xtask dist_cli
      installManPage dist/cli/man/*
      installShellCompletion --cmd owmods \
      dist/cli/completions/owmods.{bash,fish,zsh}
    ''
    + lib.optionalString wrapWithMono ''
      wrapProgram $out/bin/${meta.mainProgram} --prefix PATH : '${mono}/bin'
    '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "CLI version of the mod manager for Outer Wilds Mod Loader";
    homepage = "https://github.com/ow-mods/ow-mod-man/tree/main/owmods_cli";
    downloadPage = "https://github.com/ow-mods/ow-mod-man/releases/tag/cli_v${version}";
    changelog = "https://github.com/ow-mods/ow-mod-man/releases/tag/cli_v${version}";
    mainProgram = "owmods";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      bwc9876
      spoonbaker
      locochoco
    ];
  };
}
