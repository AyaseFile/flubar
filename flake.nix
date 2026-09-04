{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-manifest = {
      url = "https://static.rust-lang.org/dist/channel-rust-1.98.0.toml";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      fenix,
      rust-manifest,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      inherit (lib)
        genAttrs
        optionals
        optionalString
        ;

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      shellHooks = {
        x86_64-linux = ''
          export LD_LIBRARY_PATH="$(pwd)/build/linux/x64/debug/bundle/lib:$LD_LIBRARY_PATH"
          export LD_LIBRARY_PATH="$(pwd)/build/linux/x64/profile/bundle/lib:$LD_LIBRARY_PATH"
          export LD_LIBRARY_PATH="$(pwd)/build/linux/x64/release/bundle/lib:$LD_LIBRARY_PATH"
        '';
        aarch64-darwin = ''
          export SDKROOT="$(xcrun --show-sdk-path)"
        '';
      };

      forAllSystems =
        f:
        genAttrs systems (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forAllSystems (
        { pkgs, system, ... }:
        with pkgs;
        let
          _rust_toolchain = (fenix.packages.${system}.fromManifestFile rust-manifest).withComponents [
            "cargo"
            "rustc"
            "rust-src"
            "clippy"
            "rustfmt"
          ];
          rust_toolchain =
            if system == "aarch64-darwin" then
              fenix.packages.${system}.combine [
                _rust_toolchain
                (fenix.packages.${system}.targets.x86_64-apple-darwin.fromManifestFile rust-manifest).rust-std
              ]
            else
              _rust_toolchain;
        in
        {
          default = mkShellNoCC {
            nativeBuildInputs = [
              flutter347
              flutter_rust_bridge_codegen
              cargo-expand
              rust_toolchain
              cmake
              pkg-config
            ]
            ++ optionals (system == "x86_64-linux") [
              gcc
              bison
              flex
              nasm
              ninja
              # gtk3
              xz
            ]
            ++ optionals (system == "aarch64-darwin") [
              darwin.libiconv
              cocoapods
              rsync # fix permissions issue
            ];
            buildInputs = [
              ffmpeg_9-headless.dev
              mpv-unwrapped
            ];
            shellHook = ''
              export PATH="$HOME/.pub-cache/bin:$PATH"
              export CMAKE_POLICY_VERSION_MINIMUM="3.5"
              ${optionalString (system == "x86_64-linux") ''
                export LD_LIBRARY_PATH="${pkgs.mpv-unwrapped}/lib:$LD_LIBRARY_PATH"
                export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"
                export BINDGEN_EXTRA_CLANG_ARGS="-I${glibc.dev}/include -I${libclang.lib}/lib/clang/${lib.versions.major libclang.version}/include";
              ''}
              ${optionalString (system == "aarch64-darwin") ''
                export LIBRARY_PATH="${pkgs.darwin.libiconv}/lib:$LIBRARY_PATH"
                export FFMPEG_LDFLAGS="$(pkg-config --libs libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale)"
              ''}
              ${shellHooks.${system}}
            '';
            FLUTTER_ROOT = "${pkgs.flutter347}";
            RUST_SRC_PATH = "${rust_toolchain}/lib/rustlib/src/rust/library";
          };
        }
      );
    };
}
