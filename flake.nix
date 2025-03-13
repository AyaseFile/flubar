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
          nixos = mkShell {
            nativeBuildInputs =
              [
                flutter_rust_bridge_codegen
                cargo-expand
                rust_toolchain
                bison
                flex
              ]
              ++ (with pkgs; [
                cmake
                ninja
                pkg-config
              ]);

            buildInputs = [
              flutter
              mpv-unwrapped
              gtk3
              xz
            ];
            shellHook = ''
              export PATH="$HOME/.pub-cache/bin:$PATH"
              export LD_LIBRARY_PATH="${pkgs.mpv-unwrapped}/lib:$LD_LIBRARY_PATH"
              ${shellHooks.${system}}
            '';
            FLUTTER_ROOT = "${pkgs.flutter}";
            RUST_SRC_PATH = "${rust_toolchain}/lib/rustlib/src/rust/library";
          };
          default = mkShellNoCC {
            nativeBuildInputs =
              [
                flutter_rust_bridge_codegen
                cargo-expand
                rust_toolchain
                bison
                flex
              ]
              ++ (
                with pkgs;
                [
                  cmake
                  ninja
                  pkg-config
                ]
                ++ optionals (system == "aarch64-darwin") [
                  cocoapods
                ]
              );

            buildInputs =
              [
                flutter
                mpv-unwrapped
                gtk3
                xz
              ]
              ++ optionals (system == "aarch64-darwin") [
                darwin.libiconv
              ];
            shellHook = ''
              export PATH="$HOME/.pub-cache/bin:$PATH"
              export LD_LIBRARY_PATH="${pkgs.mpv-unwrapped}/lib:$LD_LIBRARY_PATH"
              ${optionalString (system == "aarch64-darwin") ''
                export LIBRARY_PATH="${pkgs.darwin.libiconv}/lib:$LIBRARY_PATH"
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
