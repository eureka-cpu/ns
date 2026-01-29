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
    Arg.(value & pos_all dirpath [] & info [] ~docv:"[SOURCE ...] [TARGET_DIR]")
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
    let doc = "enter or compose nix shells" in
    let man =
      [ `S Manpage.s_synopsis
      ; `P "ns [OPTION]… [SOURCE]… [TARGET_DIR]"
      ; `S Manpage.s_description
      ; `P "Each SOURCE is positional and may be one of:"
      ; `Pre
          "  URI#ATTR            select a devshell or package from a flake\n\
          \  URI#{DRV1,DRV2}     compose multiple packages from a flake\n\
          \  DIR#ATTR            select from a local flake\n\
          \  DIR                 use the default devshell in a directory"
      ; `P
          "If the final argument is a plain directory path, ns switches to that \
           directory before entering the subshell."
      ; `P
          "If a single SOURCE is provided and it is a directory, ns switches into it by \
           default unless a TARGET_DIR is explicitly given."
      ; `S Manpage.s_common_options
      ; `S ""
      ; `S Manpage.s_examples
      ; `Pre
          {|
Enter the default devshell in the current directory:
\$ ns .

Enter a devshell from another directory and move there:
\$ ns ../<FLAKE_DIR>#<ATTR>

Enter a devshell from another directory but stay in the current directory:
\$ ns ../<FLAKE_DIR>#devShells.<SYSTEM>.<ATTR> . # must use fully qualified syntax

Compose packages from a local flake and move there:
\$ ns ../<FLAKE_DIR>#{<DRV1>,<DRV2>}

Compose packages from a local flake but stay in the current directory:
\$ ns ../<FLAKE_DIR>#{<DRV1>,<DRV2>} .

Compose from multiple URIs:
\$ ns github:NixOS/nixpkgs#{<DRV1>,<DRV2>} github:NixOS/nixpkgs#<DRV3>

Compose and move up a directory:
\$ ns github:NixOS/nixpkgs#{<DRV1>,<DRV2>} ../<FLAKE_DIR>#<DRV3> ..
|}
      ; `S Manpage.s_exit_status
      ; `S ""
      ]
    in
    let info =
      let version =
        match Build_info.V1.version () with
        | None -> Error.handle_ns_error "missing version information"
        | Some version -> Build_info.V1.Version.to_string version
      in
      Cmd.info "ns" ~doc ~man ~version
    in
    Cmd.v info Term.(const entrypoint $ prepare_args)
  ;;

  let eval entrypoint = Cmd.eval (cmd entrypoint)
end
