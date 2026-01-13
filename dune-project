(lang dune 3.20)

(name ns)

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
  "Literally the simplest script in existence for changing directories and entering a nix shell.")
 (depends
  ocaml
  (cmdliner
   (>= 2.1.0))
  (bos
   (>= 0.2.1)))
 (tags
  ("nix" "devshell" "nix-shell" "flakes" "nix-command")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
