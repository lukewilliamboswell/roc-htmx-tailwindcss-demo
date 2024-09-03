{
  description = "devShell flake";

  inputs = {
    roc.url = "github:roc-lang/roc";
    nixpkgs.follows = "roc/nixpkgs";

    # to easily make configs for multiple architectures
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, roc, flake-utils }:
    let supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        rocPkgs = roc.packages.${system};

        sharedInputs = (with pkgs; [
          rocPkgs.cli
        ]);
      in {

        devShell = pkgs.mkShell {
          buildInputs = sharedInputs;
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
