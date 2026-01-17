{
  description = "Literally the simplest script in existence for changing directories and entering a nix shell.";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.dunix.url = "github:eureka-cpu/dunix/master";
  outputs = { self, nixpkgs, dunix }:
    let
      inherit (builtins) attrValues;
      inherit (nixpkgs.lib) genAttrs;
      inherit (nixpkgs.lib.systems) flakeExposed;
      eachSystem = f: genAttrs flakeExposed (system: f (import nixpkgs { inherit system; overlays = [ dunix.overlays.default ]; }));
    in
    {
      packages = eachSystem (pkgs:
        let
          inherit (builtins) elemAt split fetchurl attrNames foldl' listToAttrs;
          inherit (pkgs.ocamlPackages) buildDunePackage;
          inherit (pkgs.lib) cleanSource getLicenseFromSpdxId;
          cmdliner = pkgs.ocamlPackages.cmdliner.overrideAttrs (old:
            let
              version = "2.1.0";
            in
            {
              inherit version;
              src = fetchurl {
                url = "https://erratique.ch/software/${old.pname}/releases/${old.pname}-${version}.tbz";
                sha256 = "sha256:1s9lhkzrblaf1rk0b9lg95622p0jv4qmmby8xg8jzma3rlacc548";
              };
            });
          dune-project = pkgs.importDuneProject ./dune-project;
          depends = let depends = listToAttrs (map (dep: { name = dep; value = pkgs.ocamlPackages.${dep}; }) (attrNames (foldl' (acc: dep: acc // dep) { } dune-project.package.depends))); in removeAttrs depends [ "ocaml" "cmdliner" ];
        in
        {
          default = buildDunePackage {
            inherit (dune-project) version;
            pname = dune-project.package.name;
            src = cleanSource ./.;
            buildInputs = attrValues (depends // {
              inherit cmdliner;
            });
            doCheck = true;
            nativeCheckInputs = attrValues {
              inherit (pkgs) ocamlformat;
            };
            checkPhase = ''
              dune fmt
            '';
            postInstall = ''
              ${cmdliner}/bin/cmdliner install tool-support $out/bin/ns $out
              ${cmdliner}/bin/cmdliner install generic-completion $out/share
            '';
            meta =
              let
                inherit (dune-project.source) type owner repo;
                maintainers = map (m: pkgs.lib.maintainers.${(elemAt (split " " m) 0)}) dune-project.maintainers;
              in
              {
                inherit maintainers;
                description = dune-project.package.synopsis;
                longDescription = dune-project.package.description;
                homepage = "https://${type}.com/${owner}/${repo}";
                license = getLicenseFromSpdxId dune-project.license;
              };
          };
        });
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${pkgs.stdenv.hostPlatform.system}.default ];
          packages = attrValues {
            inherit (pkgs) ocamlformat nil;
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
