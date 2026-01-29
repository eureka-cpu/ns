# ns

An intuitive nix shell interface that unifies the `nix shell`, `nix develop` and `nix-shell` commands.

Rather than exposing rigid per-command options, `ns` infers intent from the structure of the expression
itself, selecting an appropriate strategy based on the system's capabilities and available entrypoints.

The entire interface can be summarized by the following excerpt of the manpage:

```
ns [OPTION]… [SOURCE]… [TARGET_DIR]
```

> Each SOURCE is positional and may be one of:
> 
>   URI#attr            select a devshell or package from a flake
>   URI#{pkg1,pkg2}     compose multiple packages from a flake
>   DIR#attr            select from a local flake
>   DIR                 use the default devshell in a directory
> 
> If the final argument is a plain directory path, ns will switch to that
> directory before entering the subshell.
> 
> If a single SOURCE is provided and it is a directory, ns switches into
> it by default unless a TARGET_DIR is explicitly given.

Try it from anywhere:

```sh
# requires flakes and nix-command experimental features
nix run github:eureka-cpu/ns -- <URI>#<ATTR>
```

Add or remove it from your user profile:

```sh
nix profile install github:eureka-cpu/ns
nix profile remove ns
```

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
