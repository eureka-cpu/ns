{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs.lib) genAttrs;
      inherit (nixpkgs.lib.systems) flakeExposed;
      eachSystem = f: genAttrs flakeExposed (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = eachSystem (pkgs: { default = pkgs.hello; });
    };
}
