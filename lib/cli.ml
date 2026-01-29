module Cli = struct
  open Cmdliner
  open Error
  open Util.Util

  (** A directory containing a nix shell entrypoint. *)
  type target_dir =
    { relative_dir : string
    ; attribute : string option
    }

  type args =
    { installables : string list
    ; target_dir : target_dir
    }

  let nix_shell_args =
    let doc =
      {|
      Any number of URIs and attributes. Passing a single directory containing a nix
      shell entrypoint will change to that directory, and use the first available resource.
      This is equivalent to calling `nix develop <DIR>#<ATTR> -c \$SHELL`, falling back 
      to `nix-shell --attr <ATTR> --command \$SHELL` on failure.

      Selecting multiple attributes from a path will assume attributes are installables 
      and invoke `nix shell <URI>#<ATTRS>`.

      Passing multiple, or non-directory URIs will assume the working directory is the 
      current directory unless the last argument is a directory without providing an
      attribute. It is equivalent to calling `nix shell <URI>#<ATTR> <URI>#<ATTR>`.

      If the flakes and nix-command experimental features are not available, 
      `nix-shell` will always be used.
      The `nixpkgs` and `pkgs` URIs are special in this case, and can be used for 
      either `nix shell` or `nix-shell`.
      This effectively unifies the two commands for simple use cases, such that `ns 
      nixpkgs#{hello,cowsay}` produces the same result.
      |}
    in
    Arg.(
      value
      & pos_all dirpath []
      & info [] ~docv:"{{ [URI[#ATTR] | URI[#{ATTRS,}]] }}" ~doc)
  ;;

  let prepare_args =
    let build nix_shell_args =
      let installables, target_dir =
        let default_target_dir = { relative_dir = Sys.getcwd (); attribute = None } in
        match List.rev nix_shell_args with
        | [] -> [], default_target_dir
        | [ target ] ->
          (match parse_target target with
           | Path relative_dir, attribute -> [], { relative_dir; attribute }
           | _ -> nix_shell_args, default_target_dir)
        | target :: rest ->
          (match parse_target target with
           | Path relative_dir, attribute -> rest, { relative_dir; attribute }
           | _ -> nix_shell_args, default_target_dir)
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
    Cmd.v info Term.(const entrypoint $ prepare_args)
  ;;

  let eval entrypoint = Cmd.eval (cmd entrypoint)
end
