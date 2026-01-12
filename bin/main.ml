open Ns

let main target_dir =
  let relative_dir, devshell = Util.parse_target target_dir in
  let absolute_dir =
    try Unix.realpath relative_dir with
    | Unix.Unix_error (e, _, _) ->
      Error.handle_ns_error "%s" (Error.sprintf_unix_error e relative_dir)
  in
  (try Unix.chdir absolute_dir with
   | Unix.Unix_error (e, _, _) ->
     Error.handle_ns_error "%s" (Error.sprintf_unix_error e absolute_dir));
  let shell = Util.get_user_shell in
  let cmd =
    match devshell with
    | Some selected_attr ->
      if Util.flake_exists_at absolute_dir
      then Printf.sprintf "nix develop %s#%s -c %s" absolute_dir selected_attr shell
      else Error.handle_ns_error "no available flake for attribute: %s\n%!" selected_attr
    | None ->
      if Util.flake_exists_at absolute_dir
      then Printf.sprintf "nix develop -c %s" shell
      else if Util.shell_exists_at absolute_dir
      then Printf.sprintf "nix-shell --command %s" shell
      else Error.handle_ns_error "no available devshell entrypoint: %s\n%!" absolute_dir
  in
  ignore (Sys.command cmd)
;;

Cli.eval main
