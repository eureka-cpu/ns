open Ns
open Ns.Cmd
open Ns.Util

let main
      ({ installables; target_info; printcmd; force_experimental_features; _ } :
        Cli.strategy)
  =
  let ({ entrypoint; attribute; subshell_dir } : Cli.target_info) = target_info in
  let strategy =
    let workdir =
      Option.value
        ~default:(Option.value ~default:(Sys.getcwd ()) entrypoint)
        subshell_dir
    and primary, fallback =
      match entrypoint with
      | Some entrypoint ->
        if Unix.flake_exists_at entrypoint
        then
          ( Cmd.nix_develop entrypoint attribute force_experimental_features
          , if Unix.shell_exists_at entrypoint
            then Some (Cmd.legacy_nix_shell_from_entrypoint entrypoint attribute)
            else None )
        else if Unix.shell_exists_at entrypoint
        then Cmd.legacy_nix_shell_from_entrypoint entrypoint attribute, None
        else Error.handle_ns_error "no available devshell entrypoint: %s\n%!" entrypoint
      | None ->
        ( Cmd.nix_shell
            (List.map Uri.uri_to_string installables)
            force_experimental_features
        , Option.map
            (fun installables -> Cmd.legacy_nix_shell_from_installables installables)
            (Uri.combine_installables_tr installables) )
    in
    { workdir; primary; fallback }
  in
  if printcmd then print_strategy strategy else execute_strategy strategy
;;

Cli.eval main
