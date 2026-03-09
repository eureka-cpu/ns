# ns

An intuitive nix shell interface that unifies the `nix shell`, `nix develop` and `nix-shell` commands.

Rather than exposing rigid per-command options, `ns` infers intent from the structure of the expression
itself, selecting an appropriate strategy based on the system's capabilities and available entrypoints.

The entire interface can be summarized by the following excerpt of the manpage:

```
ns [OPTION]… [SOURCE]… [TARGET_DIR]
```

> <pre>
> Each SOURCE is positional and may be one of:
> 
>   URI#ATTR            select a devshell or package from a flake
>   URI#{DRV1,DRV2}     compose multiple packages from a flake
>   DIR#ATTR            select from a local flake
>   DIR                 use the default devshell in a directory
> 
> If the final argument is a plain directory path, ns will switch to that
> directory before entering the subshell.
> 
> If a single SOURCE is provided and it is a directory, ns switches into
> it by default unless a TARGET_DIR is explicitly given.
> </pre>

Try it from anywhere:

```sh
# requires flakes and nix-command experimental features
nix run github:eureka-cpu/ns -- <URI>#<ATTR>
```

Add or remove it from your user profile:

```sh
nix profile add github:eureka-cpu/ns
nix profile remove ns
```

---

## Purity Constraints

Nix makes certain reproducibility guarantees, but default behavior varies in ways that can trade
reproducibility for convenience or functionality.

Without flakes, Nix does not enforce purity at evaluation time, which is why `builtins.currentSystem` works.
With flakes, evaluation is pure by default, which is why you must explicitly declare which systems
your flake supports rather than getting them at evaluation time. However, the `nix shell` and
`nix develop` commands introduced by the `nix-command` and `flakes` experimental features have no
equivalent to `nix-shell --pure` and there is no current way to get environment purity from these commands.

For this reason, `ns` treats `nix-shell` as the only viable command when purity is a requirement.
If both flakes and environment purity are non-negotiable, the following pattern bridges the two:

1. Define your `devShells` in `flake.nix`:

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs.lib) genAttrs systems;
      eachSystem = f: genAttrs systems.flakeExposed (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            hello
          ];
        };
      });
    };
}
```

2. Expose your flake's `devShell` via `shell.nix`:

```nix
(builtins.getFlake (toString ./.)).outputs.devShells.${builtins.currentSystem}.default
```

`nix-shell --pure` will now use the pinned derivation from your flake. The tradeoff is that system
tools are no longer available in the shell:

```sh
ns --pure
git --version
# bash: git: command not found
hello
# Hello, world!
```

This is easily resolved by adding the tools you need to `packages` in your `mkShell`.

---

### macOS Sandboxing

Nix on macOS sets `sandbox = false` in `nix.conf` by default, because sandboxing breaks certain
functionality on Darwin. It's worth being precise about what this affects: sandboxing governs how
packages are *built*, not the purity of the environment in which you use them. The flake evaluation
purity described above is a separate concern.

`ns` does not attempt to work around this — it is a macOS-level constraint, not something a wrapper
can meaningfully solve. In most cases, simply knowing that packages are built without sandboxing on
macOS is enough context for debugging. For example, if a package behaves differently on macOS than on
Linux, the sandbox difference is a likely culprit. You can test this hypothesis for a one-off build
with `--option sandbox true`, but enabling it permanently in `nix.conf` is not recommended as it can
cause difficult-to-diagnose failures.

---

## Contributing

> [!Important]
> Additional options and flags are intentionally limited to avoid cluttering the interface.
> It is the opinion of the maintainers of this package that such options are better off as
> part of a `flake.nix` devshell, `shell.nix`, or system configuration, where such options
> are homogenous with the design of `ns.` Please take this into consideration and explore
> other options before opening issues or pull requests.

Fork the repository on GitHub, then:

```sh
git clone git@github.com:USERNAME/ns.git
nix profile install github:eureka-cpu/ns
ns ns
```

Open an issue and submit a pull request with closing keywords.
