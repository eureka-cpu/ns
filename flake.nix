{
  description = "Literally the simplest script in existence for changing directories and entering a nix shell.";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let
      inherit (nixpkgs.lib) genAttrs;
      inherit (nixpkgs.lib.systems) flakeExposed;
      eachSystem = f: genAttrs flakeExposed (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = eachSystem (pkgs: {
        default = pkgs.writeShellApplication {
          name = "ns";
          text = builtins.readFile ./ns;
        };
      });
    };
}
