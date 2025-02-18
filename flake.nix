{
  description = "merl-an Nix Flake";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.cb-repository = {
    url = "github:ocurrent/current-bench";
    flake = false;
  };
  # We're using custom merlin from Sonja's branch.
  # It's an old fork without flake.nix, thus we build it the hard way.
  inputs.merlin-repository = {
    url = "github:ocaml/merlin/main";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, cb-repository, merlin-repository }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs.ocamlPackages) buildDunePackage;
        cb-check = buildDunePackage {
          pname = "cb-check";
          src = cb-repository;
          version = "n/a";
          duneVersion = "3";
          buildInputs = with pkgs.ocamlPackages; [
            ocaml
            yojson
          ];
        };
        merlin-lib = buildDunePackage {
            pname = "merlin-lib";
            version = "dev";
            src = merlin-repository;
            duneVersion = "3";
            propagatedBuildInputs = with pkgs.ocamlPackages; [
              csexp
            ];
            doCheck = true;
          };
        dot-merlin-reader = buildDunePackage {
            pname = "dot-merlin-reader";
            version = "dev";
            src = merlin-repository;
            duneVersion = "3";
            propagatedBuildInputs = [
              pkgs.ocamlPackages.findlib
            ];
            buildInputs = [
              merlin-lib
            ];
            doCheck = true;
          };
        merlin = buildDunePackage {
            pname = "merlin";
            version = "dev";
            src = merlin-repository;
            duneVersion = "3";
            buildInputs = [
              merlin-lib
              dot-merlin-reader
              pkgs.ocamlPackages.menhirLib
              pkgs.ocamlPackages.menhirSdk
              pkgs.ocamlPackages.yojson
            ];
            nativeBuildInputs = [
              pkgs.ocamlPackages.menhir
              pkgs.jq
            ];
            nativeCheckInputs = [ dot-merlin-reader ];
            checkInputs = with pkgs.ocamlPackages; [
              ppxlib
            ];
            doCheck = false;
            meta = with pkgs; {
              mainProgram = "ocamlmerlin";
            };
          };
      in
        rec {
          packages = rec {
            default = merl-an;
            merl-an = buildDunePackage {
              pname = "merl-an";
              version = "n/a";
              src = ./.;
              duneVersion = "3";
              nativeBuildInputs = [
                pkgs.jq
                merlin
                cb-check
              ];
              buildInputs = with pkgs.ocamlPackages;
                [
                    ocaml
                    ppxlib
                    yojson
                    fpath
                    bos
                    cmdliner
                    ppx_deriving_yojson
                    ppx_enumerate
                    ppx_fields_conv
                    ppx_yojson_conv
                    ptime
                ];
              checkInputs =
                [ merlin
                ];
              doCheck = true;
            };
          };
          devShells.default = pkgs.mkShell {
            inputsFrom = pkgs.lib.attrValues packages;
            buildInputs = with pkgs.ocamlPackages; [
              pkgs.ocamlformat_0_27_0
              cb-check
              ocaml-lsp
              pkgs.jq
            ];
          };
        });
}
