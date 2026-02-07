open Ns
open Ns.Cmd
open Ns.Util

let main
      ({ installables; target_info; printcmd; force_experimental_features } :
        Cli.strategy)
  =
  let ({ entrypoint; attribute; subshell_dir } : Cli.target_info) = target_info in
  Option.value ~default:(Option.value ~default:(Sys.getcwd ()) entrypoint) subshell_dir
  |> Unix.cd;
  let cmd =
    match entrypoint with
    | Some entrypoint ->
      (match Unix.flake_exists_at entrypoint with
       | true ->
         Cmd.builder "nix"
         |>+ [ "develop" ] @ [ Uri.sprintf_uri_attr_opt entrypoint attribute ]
         |>+ Option.value ~default:[] force_experimental_features
       | false ->
         (match Unix.shell_exists_at entrypoint with
          | true ->
            Cmd.builder "nix-shell"
            |>+ Option.value
                  ~default:[]
                  (Option.map (fun attr -> [ "--attr"; attr ]) attribute)
            |>+ [ entrypoint ]
          | false ->
            Error.handle_ns_error "no available devshell entrypoint: %s\n%!" entrypoint))
      |>+ [ "--command"; Unix.shell ]
    | None ->
      Cmd.builder "nix"
      |>+ [ "shell" ]
      |>+ installables
      |>+ Option.value ~default:[] force_experimental_features
  in
  if printcmd then print_endline (Cmd.to_string cmd) else ignore (Cmd.run cmd)
;;

Cli.eval main
