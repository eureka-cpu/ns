module Cli = struct
  open Cmdliner
  open Error

  type args =
    { installables : string list
    ; target_dir : string
    }

  let nix_shell_args =
    let doc = "
      Any number of URIs and attributes.

      Passing a single directory containing a nix shell entrypoint will change to that directory, and use the first available resource.
      This is equivalent to calling `nix develop <DIR>#<ATTR> -c $SHELL`, falling back to `nix-shell --attr <ATTR> --command $SHELL` on failure.
      Selecting multiple attributes from a path will assume attributes are installables and invoke `nix shell <URI>#<ATTRS>`.

      Passing multiple, or non-directory URIs will assume the working directory is the current directory
      unless the last argument is a directory that does not have an attribute.
      It is equivalent to calling `nix shell <URI>#<ATTR> <URI>#<ATTR>`.

      If the flakes and nix-command experimental features are not available, `nix-shell` will always be used.
      The `nixpkgs` and `pkgs` URIs are special in this case, and can be used for either `nix shell` or `nix-shell`.
      This effectively unifies the two commands for simple use cases, such that `ns nixpkgs#{hello,cowsay}` produces the same result.
    " in
    Arg.(value & pos_all dirpath [] & info [] ~docv:"{{ [URI[#ATTR] | URI[#{ATTRS}]] }}" ~doc)
  ;;

  let args =
    let build nix_shell_args =
      let installables, target_dir =
        match nix_shell_args with
        | [] -> [], Sys.getcwd ()
        (* TODO: Check if maybe_attrpath is actually a directory *)
        | [maybe_attrpath] -> [], maybe_attrpath
        (* TODO: Check if the last argument is a directory without an attribute *)
        | _ -> nix_shell_args, Sys.getcwd ()
      in
      { installables; target_dir }
    in
    Term.(const build $ nix_shell_args)
  ;;

  let cmd entrypoint =
    let doc = "Enter a nix development shell in the target directory" in
    let info =
      let version =
        match Build_info.V1.version () with
        | None -> Error.handle_ns_error "missing version information"
        | Some version -> Build_info.V1.Version.to_string version
      in
      Cmd.info "ns" ~doc ~version
    in
    Cmd.v info Term.(const entrypoint $ args)
  ;;

  let eval entrypoint = Cmd.eval (cmd entrypoint)
end
