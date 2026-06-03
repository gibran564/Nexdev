{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    naersk.url = "github:nix-community/naersk";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    naersk,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      naerskLib = pkgs.callPackage naersk {};

      darwinDeps = pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
        libiconv
        darwin.apple_sdk.frameworks.Security
        darwin.apple_sdk.frameworks.SystemConfiguration
      ]);
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs;
          [
            cargo
            rustc
            fzf
            pkg-config
            glib
          ]
          ++ darwinDeps;
      };

      packages.default = naerskLib.buildPackage {
        src = ./.;

        nativeBuildInputs = [pkgs.pkg-config pkgs.makeWrapper];

        buildInputs = [pkgs.glib] ++ darwinDeps;

        postInstall = ''
          wrapProgram $out/bin/nexdev \
            --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.fzf]}
        '';
      };
    });
}
