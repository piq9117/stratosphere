{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
  outputs = {self, nixpkgs}: 
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      nixpkgsFor = forAllSystems(system: import nixpkgs {
        inherit system;
        overlays = [ self.overlays ];
      });
    in {
      overlays = final: prev: {
        hsPkgs = prev.haskell.packages.ghc984.override {
          overrides = hfinal: hprev: {
            attoparsec = hprev.callHackage "attoparsec" "0.14.4" {};
            attoparsec-aeson = hprev.attoparsec-aeson.override {
              attoparsec = hfinal.attoparsec;
            };
            stratosphere = hfinal.callCabal2nix "stratosphere" ./. {};
          };
        };
        stratosphere-ec2 = final.hsPkgs.callCabal2nix "stratosphere-ec2" ./services/ec2 {
          stratosphere = final.hsPkgs.stratosphere;
        };
      };


      devShells = forAllSystems(system: 
        let
          pkgs = nixpkgsFor.${system};
          stack-wrapped = pkgs.symlinkJoin {
            name = "stack";
            paths = [ pkgs.stack ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/stack \
                --add-flags "\
                  --no-nix \
                  --system-ghc \
                  --no-install-ghc \
                "
            '';
          };
          devTools = with pkgs; [
            zlib
            hsPkgs.ghc
            hsPkgs.haskell-language-server
            hsPkgs.hpack
            pkgconf
            stack-wrapped
            hsPkgs.cabal-install
            ormolu
            treefmt
          ];
        in {
          default = pkgs.hsPkgs.shellFor {
            packages = hsPkgs: [
            ];
            buildInputs = devTools;
            nativeBuildInputs = with pkgs; [
              pkg-config
            ];
            shellHook = ''
              export PS1='[$PWD]\n❄ '
            '';
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath devTools;
            STACK_YAML = "stack-9.8.yaml";
          };
        });
    };
}
