(lang dune 3.20)

(name ns)

(version 0.4.3)

(generate_opam_files true)

(source
 (github eureka-cpu/ns))

(authors "eureka-cpu <github.eureka@gmail.com>")

(maintainers "eureka-cpu <github.eureka@gmail.com>")

(license MIT)

(package
 (name ns)
 (synopsis "A unified interface for nix shell.")
 (description
  "An intuitive nix shell interface that unifies the `nix shell`, `nix develop` and `nix-shell` commands.")
 (depends
  ocaml
  (cmdliner
   (>= 2.1.0))
  (bos
   (>= 0.2.1))
  (dune-build-info
   (>= 3.20.2)))
 (tags
  ("nix"
   "nix shell"
   "nix develop"
   "devshell"
   "nix-shell"
   "flakes"
   "nix-command")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
