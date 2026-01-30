open Ns
open Ns.Cmd
open Ns.Util

let main ({ installables; target_info } : Cli.args) =
  let ({ entrypoint; attribute; subshell_dir } : Cli.target_info) = target_info in
  let entrypoint = Option.map realpath entrypoint in
  Option.value ~default:(Option.value ~default:(Sys.getcwd ()) entrypoint) subshell_dir
  |> cd;
  let cmd =
    match entrypoint with
    | Some entrypoint ->
      (match flake_exists_at entrypoint with
       | true ->
         Cmd.builder "nix"
         |>+ [ "develop" ]
             @ [ Option.value
                   ~default:entrypoint
                   (Option.map
                      (fun attr -> Printf.sprintf "%s#%s" entrypoint attr)
                      attribute)
               ]
       | false ->
         (match shell_exists_at entrypoint with
          | true ->
            Cmd.builder "nix-shell"
            |>+ Option.value
                  ~default:[]
                  (Option.map (fun attr -> [ "--attr"; attr ]) attribute)
            |>+ [ entrypoint ]
          | false ->
            Error.handle_ns_error "no available devshell entrypoint: %s\n%!" entrypoint))
      |>+ [ "--command"; shell ]
    | None -> Cmd.builder "nix" |>+ [ "shell" ] |>+ installables
  in
  Printf.eprintf "DEBUG: %s\n%!" (Bos.Cmd.to_string cmd);
  ignore (Cmd.run cmd)
;;

Cli.eval main
