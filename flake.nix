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
          zigVersion = "0.15.2";
          zigTargets = {
            aarch64-darwin = {
              name = "aarch64-macos";
              hash = "sha256-PMK6s2fhhc37J1AcSzCxsGU8KNn3PfjckUiOZuzl+ms=";
            };
            aarch64-linux = {
              name = "aarch64-linux";
              hash = "sha256-lY7X0eANDqdlkNJ2Zu+/epMigbPXugxrAbD/JkmPZn8=";
            };
            x86_64-linux = {
              name = "x86_64-linux";
              hash = "sha256-AqonDxg9onbltZILHaxEpj8aSeVQUOveOuzJ64L5Mjk=";
            };
          };
          zigTarget = zigTargets.${system} or (throw "zig-keychain flake does not provide Zig ${zigVersion} for ${system}");
          zig = pkgs.stdenv.mkDerivation {
            pname = "zig";
            version = zigVersion;
            src = pkgs.fetchurl {
              url = "https://ziglang.org/download/${zigVersion}/zig-${zigTarget.name}-${zigVersion}.tar.xz";
              hash = zigTarget.hash;
            };
            nativeBuildInputs = [ pkgs.gnutar pkgs.xz ];
            dontConfigure = true;
            dontBuild = true;
            installPhase = ''
              mkdir -p $out/bin $out/lib/zig
              tar -xJf $src --strip-components=1 -C $out/lib/zig
              ln -s $out/lib/zig/zig $out/bin/zig
            '';
          };
        in
        {
          devShells.default = pkgs.mkShell {
            packages = [
              zig
              pkgs.just
              pkgs.python3Packages.detect-secrets
              pkgs.python3Packages.mkdocs-material
              pkgs.python3Packages.pymdown-extensions
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
