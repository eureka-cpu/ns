{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = builtins.attrValues {
    inherit (pkgs) hello;
  };
}
