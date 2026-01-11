# ns

Literally the simplest script in existence for changing directories and entering a nix shell.

Try it from anywhere:

```sh
# requires flakes and nix-command experimental features
nix run github:eureka-cpu/ns -- <DIR>#<ATTR>
```

Add or remove it from your user profile:

```sh
nix profile install github:eureka-cpu/ns
nix profile remove ns
```

## Contributing

Fork the repository on GitHub, then:

```sh
git clone git@github.com:USERNAME/ns.git
nix profile install github:eureka-cpu/ns
ns ns
```

Open an issue and submit a pull request with closing keywords.
