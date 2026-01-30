module Cli = struct
  open Cmdliner
  open Error
  open Util.Util

  (** The a directory containing a nix shell entrypoint, its attribute selection
    and the directory to start the subshell. *)
  type target_info =
    { entrypoint : string option
    ; attribute : string option
    ; subshell_dir : string option
    }

  type args =
    { installables : string list
    ; target_info : target_info
    }

  let nix_shell_args = Arg.(value & pos_all dirpath [] & info [])

  (** Organize the args so that the main function knows what to do with them. *)
  let prepare_args =
    let build original_args =
      let installables, target_info =
        let default_installables = []
        and default_target =
          { entrypoint = None; attribute = None; subshell_dir = None }
        in
        match List.rev original_args with
        (* Args was empty. *)
        | [] ->
          ( default_installables
          , { entrypoint = Some (Sys.getcwd ()); attribute = None; subshell_dir = None } )
        (* Single arg passed. *)
        | [ target ] ->
          (match parse_target target with
           (* The multiattr behavior is handled by the default, so we only need to handle the case where
             a single arg is passed that is a directory with up to one attribute *)
           | LocalResourceMaybeAttr (entrypoint, attribute) ->
             ( default_installables
             , { entrypoint = Some entrypoint; attribute; subshell_dir = None } )
           | _ -> original_args, default_target)
        (* Two args passed. *)
        | [ maybe_subshell_dir; target ] ->
          (match parse_target maybe_subshell_dir, parse_target target with
           (* If maybe_subshell_dir does not have any attributes we know the user wants to change directories
             and we only need to support LocalResourceMaybeAttr for target since the default behavior is already defined *)
           | ( LocalResourceMaybeAttr (subshell_dir, None)
             , LocalResourceMaybeAttr (entrypoint, attribute) ) ->
             ( default_installables
             , { entrypoint = Some entrypoint
               ; attribute
               ; subshell_dir = Some subshell_dir
               } )
           | _ -> original_args, default_target)
        (* Three or more args passed. *)
        | maybe_subshell_dir :: remaining ->
          (match parse_target maybe_subshell_dir with
           (* If maybe_subshell_dir does not have attributes,
             its the directory the user wants to go to before entering the subshell *)
           | LocalResourceMaybeAttr (subshell_dir, None) ->
             ( remaining
             , { entrypoint = None; attribute = None; subshell_dir = Some subshell_dir } )
           | _ -> original_args, default_target)
      in
      { installables; target_info }
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

Enter a devshell from another directory and move to the flake directory:
\$ ns ../<FLAKE_DIR>#<ATTR>

Enter a devshell from another directory but stay in the current directory:
\$ ns ../<FLAKE_DIR>#<ATTR> .

Compose packages from a local flake and move to the flake directory:
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
