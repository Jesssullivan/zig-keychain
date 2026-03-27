{
  description = "zig-keychain — Portable keychain/secrets abstraction in Zig";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { pkgs, system, ... }:
        let
          zig = pkgs.zig_0_14;
        in
        {
          devShells.default = pkgs.mkShell {
            packages = [
              zig
              pkgs.just
              pkgs.python3Packages.detect-secrets
              pkgs.pre-commit
            ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.Security
              pkgs.darwin.apple_sdk.frameworks.CoreFoundation
            ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
              pkgs.libsecret
              pkgs.glib
              pkgs.pkg-config
            ];

            shellHook = ''
              echo "zig-keychain dev shell — zig $(zig version 2>/dev/null || echo 'not found')"
            '';
          };
        };
    };
}
