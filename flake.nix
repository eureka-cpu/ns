{
  description = "Literally the simplest script in existence for changing directories and entering a nix shell.";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs, ... }:
    let
      inherit (builtins) attrValues;
      inherit (nixpkgs.lib) genAttrs;
      inherit (nixpkgs.lib.systems) flakeExposed;
      eachSystem = f: genAttrs flakeExposed (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = eachSystem (pkgs:
        let
          inherit (pkgs.ocamlPackages) buildDunePackage;
          inherit (pkgs.lib) cleanSource;
          cmdliner = pkgs.ocamlPackages.cmdliner.overrideAttrs (old:
            let
              version = "2.1.0";
            in
            {
              inherit version;
              src = builtins.fetchurl {
                url = "https://erratique.ch/software/${old.pname}/releases/${old.pname}-${version}.tbz";
                sha256 = "sha256:1s9lhkzrblaf1rk0b9lg95622p0jv4qmmby8xg8jzma3rlacc548";
              };
            });
        in
        {
          default = buildDunePackage {
            pname = "ns";
            version = "0.2.0";
            src = cleanSource ./.;
            buildInputs = attrValues {
              inherit cmdliner;
            };
            doCheck = true;
            nativeCheckInputs = attrValues {
              inherit (pkgs) ocamlformat;
            };
            checkPhase = ''
              dune fmt
            '';
            postInstall = ''
              mkdir -p $out/share/bash-completion/completions
              ${cmdliner}/bin/cmdliner tool-completion --standalone-completion bash ns > $out/share/bash-completion/completions/ns
              mkdir -p $out/share/zsh/site-functions
              ${cmdliner}/bin/cmdliner tool-completion --standalone-completion zsh ns > $out/share/zsh/site-functions/_ns
            '';
            meta.license = pkgs.lib.licenses.mit;
          };
        });
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${pkgs.stdenv.hostPlatform.system}.default ];
          packages = attrValues {
            inherit (pkgs) ocamlformat;
            inherit (pkgs.ocamlPackages) ocaml-lsp odoc;
          };
          shellHook = ''
            dune build # Ensure build artifacts exist for LSP
          '';
        };
      });
      formatter = eachSystem (pkgs: pkgs.nixpkgs-fmt);
    };
}
