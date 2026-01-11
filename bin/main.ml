open Cmdliner

let version = "0.1.0"

(** Parse target argument for optional attribute selection *)
let parse_target maybe_attrpath =
  match String.split_on_char '#' maybe_attrpath with
  | [ dir ] -> dir, None
  | [ dir; devshell ] -> dir, Some devshell
  | _ ->
    Printf.eprintf "ns: invalid path or attribute selection syntax: %s\n%!" maybe_attrpath;
    exit 1
;;

let main target_dir =
  let relative_dir, devshell = parse_target target_dir in
  let absolute_dir =
    try Unix.realpath relative_dir with
    | Unix.Unix_error (e, _, _) ->
      Printf.eprintf
        "ns: %s: %s\n%!"
        (String.uncapitalize_ascii (Unix.error_message e))
        relative_dir;
      exit 1
  in
  (try Unix.chdir absolute_dir with
   | Unix.Unix_error (e, _, _) ->
     Printf.eprintf
       "ns: %s: %s\n%!"
       (String.uncapitalize_ascii (Unix.error_message e))
       absolute_dir;
     exit 1);
  let shell =
    match Sys.getenv_opt "SHELL" with
    | Some s -> s
    | None -> "/bin/sh"
  in
  let cmd =
    match devshell with
    | Some selected_attr ->
      (* TODO: It would be kinda cool to allow # for shell.nix
        since you can already select attributes via nix-shell -A *)
      if Sys.file_exists (Filename.concat absolute_dir "flake.nix")
      then Printf.sprintf "nix develop %s#%s -c %s" absolute_dir selected_attr shell
      else (
        Printf.eprintf "ns: no available flake for attribute: %s\n%!" selected_attr;
        exit 1)
    | None ->
      if Sys.file_exists (Filename.concat absolute_dir "flake.nix")
      then Printf.sprintf "nix develop -c %s" shell
      else if Sys.file_exists (Filename.concat absolute_dir "shell.nix")
      then Printf.sprintf "nix-shell --command %s" shell
      else (
        Printf.eprintf "ns: no available devshell entrypoint: %s\n%!" absolute_dir;
        exit 1)
  in
  ignore (Sys.command cmd)
;;

let target_dir =
  let doc = "Target directory with optional attribute" in
  Arg.(required & pos 0 (some dirpath) None & info [] ~docv:"DIR[#ATTR]" ~doc)
;;

let cmd =
  let doc = "Enter a nix development shell in the target directory" in
  let info = Cmd.info "ns" ~doc ~version in
  Cmd.v info Term.(const main $ target_dir)
;;

exit (Cmd.eval cmd)
