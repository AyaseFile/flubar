{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, fenix, ... }:
    let
      inherit (nixpkgs) lib;
      inherit (lib) optionals optionalString;

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
          export PATH="/Library/Developer/CommandLineTools/usr/bin:$PATH"
          export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
        '';
      };

      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
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
          rust_toolchain = fenix.packages.${system}.stable.withComponents [
            "cargo"
            "rustc"
            "rust-src"
            "clippy"
            "rustfmt"
          ];
        in
        {
          default = mkShellNoCC {
            nativeBuildInputs = [
              flutter335
              flutter_rust_bridge_codegen
              cargo-expand
              rust_toolchain
              cmake
              pkg-config
            ]
            ++ optionals (system == "x86_64-linux") [
              clang
              libclang
              ninja
              bison
              flex
              # gtk3
              xz
            ]
            ++ optionals (system == "aarch64-darwin") [
              darwin.libiconv
              cocoapods
              rsync # fix permissions issue
            ];
            buildInputs = [
              ffmpeg.dev
            ]
            ++ optionals (system == "x86_64-linux") [
              mpv-unwrapped
            ];
            shellHook = ''
              export PATH="$HOME/.pub-cache/bin:$PATH"
              ${optionalString (system == "x86_64-linux") ''
                export LD_LIBRARY_PATH="${pkgs.mpv-unwrapped}/lib:$LD_LIBRARY_PATH"
                export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"
              ''}
              ${optionalString (system == "aarch64-darwin") ''
                export LIBRARY_PATH="${pkgs.darwin.libiconv}/lib:$LIBRARY_PATH"
                export FFMPEG_LDFLAGS="$(pkg-config --libs libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale)"
              ''}
              ${shellHooks.${system}}
            '';
            FLUTTER_ROOT = "${pkgs.flutter}";
            RUST_SRC_PATH = "${rust_toolchain}/lib/rustlib/src/rust/library";
          };
        }
      );
    };
}
