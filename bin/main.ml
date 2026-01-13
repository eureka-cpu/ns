open Ns
open Ns.Cmd
open Ns.Util

let main target_dir =
  let relative_dir, attribute = parse_target target_dir in
  let entrypoint = realpath relative_dir |> cd in
  let cmd =
    (match flake_exists_at entrypoint with
     | true ->
       Cmd.builder "nix"
       |>+ [ "develop" ]
           @ Option.to_list
               (Option.map (fun attr -> Printf.sprintf "%s#%s" entrypoint attr) attribute)
     | false ->
       (match shell_exists_at entrypoint with
        | true ->
          Cmd.builder "nix-shell"
          |>+ Option.value
                ~default:[]
                (Option.map (fun attr -> [ "--attr"; attr ]) attribute)
        | false ->
          Error.handle_ns_error "no available devshell entrypoint: %s\n%!" entrypoint))
    |>+ [ "--command"; shell ]
  in
  ignore (Cmd.run cmd)
;;

Cli.eval main
