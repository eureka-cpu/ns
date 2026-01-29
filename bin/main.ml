open Ns
open Ns.Cmd
open Ns.Util

let main ({ installables; target_dir } : Cli.args) =
  let ({ relative_dir; attribute } : Cli.target_dir) = target_dir in
  let entrypoint = realpath relative_dir |> cd in
  let cmd =
    if not (List.is_empty installables)
    then Cmd.builder "nix" |>+ [ "shell" ] |>+ installables
    else
      (match flake_exists_at entrypoint with
       | true ->
         Cmd.builder "nix"
         |>+ [ "develop" ]
             @ Option.to_list
                 (Option.map
                    (fun attr -> Printf.sprintf "%s#%s" entrypoint attr)
                    attribute)
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
